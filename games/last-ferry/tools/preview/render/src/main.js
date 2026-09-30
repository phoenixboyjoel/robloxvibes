// Renders one exported scene: the 3D view from the player's camera with Roblox-like
// post-processing (bloom for Neon, ColorCorrection, Blur), then the player's
// ScreenGuis and an approximation of Roblox's top bar over it.

import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { drawScreenGuis, loadFontsFor } from './gui.js';
import { buildWorld, cframeMatrix } from './world.js';

const params = new URLSearchParams(location.search);

async function loadImage(url) {
  return new Promise((resolve) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = () => resolve(null);
    image.src = url;
  });
}

// Built-in rbxasset:// content is served from rbxcontent/ (see fetch-content.mjs);
// uploaded assets (rbxassetid://) aren't available offline.
function localPath(content) {
  if (typeof content !== 'string' || !content.startsWith('rbxasset://')) return null;
  return `rbxcontent/${content.slice('rbxasset://'.length).replace(/\.dds$/i, '.png')}`;
}

function collectContent(node, into) {
  if (!node) return into;
  for (const key of ['Texture', 'Image', 'ColorMap']) {
    const value = node.props?.[key];
    if (typeof value === 'string' && value.startsWith('rbxasset://')) into.add(value);
  }
  for (const child of node.children ?? []) collectContent(child, into);
  return into;
}

const ColorCorrectionShader = {
  uniforms: {
    tDiffuse: { value: null },
    brightness: { value: 0 },
    contrast: { value: 0 },
    saturation: { value: 0 },
    tint: { value: new THREE.Color(1, 1, 1) },
  },
  vertexShader: `varying vec2 vUv; void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`,
  fragmentShader: `
    uniform sampler2D tDiffuse; uniform float brightness; uniform float contrast; uniform float saturation; uniform vec3 tint;
    varying vec2 vUv;
    void main() {
      vec4 c = texture2D(tDiffuse, vUv);
      vec3 rgb = c.rgb + brightness;
      rgb = (rgb - 0.18) * (1.0 + contrast) + 0.18;
      float l = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
      rgb = mix(vec3(l), rgb, 1.0 + saturation);
      gl_FragColor = vec4(max(rgb * tint, 0.0), c.a);
    }`,
};

function drawTopBar(ctx, screen) {
  // The Roblox menu button and the chat pill in the top-left, roughly as the current
  // client draws them. Decorative: it shows what the safe area is keeping clear.
  const y = 12;
  const size = 44;
  ctx.save();
  ctx.fillStyle = 'rgba(18, 18, 21, 0.72)';
  ctx.beginPath();
  ctx.arc(12 + size / 2, y + size / 2, size / 2, 0, Math.PI * 2);
  ctx.fill();
  ctx.translate(12 + size / 2, y + size / 2);
  ctx.rotate((15 * Math.PI) / 180);
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(-9, -9, 18, 18);
  ctx.fillStyle = 'rgba(18, 18, 21, 1)';
  ctx.fillRect(-3, -3, 6, 6);
  ctx.restore();
  ctx.save();
  const x = 12 + size + 8;
  ctx.fillStyle = 'rgba(18, 18, 21, 0.72)';
  ctx.beginPath();
  ctx.roundRect(x, y, 96, size, size / 2);
  ctx.fill();
  ctx.strokeStyle = '#ffffff';
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.roundRect(x + 14, y + 13, 20, 15, 4);
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(x + 19, y + 28);
  ctx.lineTo(x + 17, y + 33);
  ctx.lineTo(x + 24, y + 28);
  ctx.stroke();
  for (let i = 0; i < 3; i++) {
    ctx.fillStyle = '#ffffff';
    ctx.beginPath();
    ctx.arc(x + 58 + i * 8, y + size / 2, 2.2, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.restore();
  return screen;
}

// Lua's empty tables encode as {} whatever they held, so make every node's children
// an array and its props an object before anything walks the tree.
function normalize(node) {
  if (!node) return;
  node.children = Array.isArray(node.children) ? node.children : [];
  node.props = node.props && !Array.isArray(node.props) ? node.props : {};
  for (const child of node.children) normalize(child);
}

function indexNodes(node, into, parent = null) {
  if (!node) return into;
  node.parent = parent;
  into.set(node.id, node);
  for (const child of node.children) indexNodes(child, into, node);
  return into;
}

// Roblox's default ProximityPrompt (CoreScripts/ProximityPrompt.lua), for prompts the
// player's character is close enough to: a 72 px dark pill, the key in a grey circle,
// the object text above the action text. Always on top, centred on its attachment.
async function drawPrompts(ctx, data, partsById, nodesById, camera, W, H) {
  const character = nodesById.get(data.localCharacter);
  if (!character) return;
  const rootNode = character.children.find((c) => c.name === 'HumanoidRootPart');
  const root = rootNode && partsById.get(rootNode.id);
  if (!root) return;
  const rootPosition = new THREE.Vector3().setFromMatrixPosition(root.world);
  const font = { family: 'rbxasset://fonts/families/BuilderSans.json', weight: 'Medium', style: 'Normal' };
  await loadFontsFor({ props: { FontFace: font }, children: [] });
  const { canvasFont } = await import('./fonts.js');
  for (const node of nodesById.values()) {
    if (node.class !== 'ProximityPrompt' || node.props.Enabled === false) continue;
    const holder = node.parent;
    let position = null;
    if (holder?.class === 'Attachment' && partsById.get(holder.parent?.id)) {
      const local = cframeMatrix(holder.props.CFrame ?? [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]);
      position = new THREE.Vector3().setFromMatrixPosition(
        partsById.get(holder.parent.id).world.clone().multiply(local),
      );
    } else if (holder && partsById.get(holder.id)) {
      position = new THREE.Vector3().setFromMatrixPosition(partsById.get(holder.id).world);
    }
    if (!position || position.distanceTo(rootPosition) > (node.props.MaxActivationDistance ?? 10)) continue;
    const screen = position.clone().project(camera);
    if (screen.z > 1) continue;
    const cx = ((screen.x + 1) / 2) * W;
    const cy = ((1 - screen.y) / 2) * H;
    const action = node.props.ActionText ?? '';
    const object = node.props.ObjectText ?? '';
    ctx.save();
    ctx.font = canvasFont(font, 19);
    const actionWidth = ctx.measureText(action).width;
    ctx.font = canvasFont(font, 14);
    const objectWidth = ctx.measureText(object).width;
    const width = 72 + Math.max(actionWidth, objectWidth) + (object ? 15 : 24);
    const left = cx - width / 2;
    const top = cy - 36;
    ctx.fillStyle = 'rgba(18, 18, 18, 0.8)';
    ctx.beginPath();
    ctx.roundRect(left, top, width, 72, 8);
    ctx.fill();
    ctx.fillStyle = 'rgba(163, 162, 165, 0.5)';
    ctx.beginPath();
    ctx.arc(left + 36, top + 36, 24, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(left + 36 - 12, top + 36 - 14, 24, 26, 5);
    ctx.stroke();
    ctx.fillStyle = '#ffffff';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.font = canvasFont(font, 16);
    ctx.fillText(node.props.KeyboardKeyCode ?? 'E', left + 36, top + 35);
    ctx.textAlign = 'left';
    if (object) {
      ctx.font = canvasFont(font, 14);
      ctx.fillStyle = 'rgb(179, 179, 179)';
      ctx.fillText(object, left + 72, top + 26);
    }
    ctx.font = canvasFont(font, 19);
    ctx.fillStyle = '#ffffff';
    ctx.fillText(action, left + 72, top + (object ? 45 : 36));
    ctx.restore();
  }
}

// Where Roblox anchors a bubble: over a part, its top; over a model, the top of the
// model's bounding box above its HumanoidRootPart (so it clears hats), as ExpChat's
// BubbleChatBillboard:getVerticalOffset does. Then 1 stud up (its StudsOffset).
function bubbleAnchor(id, partsById, nodesById) {
  const part = partsById.get(id);
  if (part) {
    const size = part.node.props.Size ?? [1, 1, 1];
    return new THREE.Vector3(0, size[1] / 2 + 1, 0).applyMatrix4(part.world);
  }
  const model = nodesById.get(id);
  if (!model || model.class !== 'Model') return null;
  const box = new THREE.Box3();
  let root = null;
  const walk = (node) => {
    const entry = partsById.get(node.id);
    if (entry) {
      const [x, y, z] = entry.node.props.Size ?? [1, 1, 1];
      const local = new THREE.Box3(new THREE.Vector3(-x / 2, -y / 2, -z / 2), new THREE.Vector3(x / 2, y / 2, z / 2));
      box.union(local.applyMatrix4(entry.world));
      if (node.name === 'HumanoidRootPart' || (!root && node.id === model.props.PrimaryPart)) root = entry;
    }
    for (const child of node.children) walk(child);
  };
  walk(model);
  if (box.isEmpty()) return null;
  const centre = root ? new THREE.Vector3().setFromMatrixPosition(root.world) : box.getCenter(new THREE.Vector3());
  return new THREE.Vector3(centre.x, box.max.y + 1, centre.z);
}

// Roblox's chat bubbles (TextChatService:DisplayBubble) in their default style: a white
// rounded bubble with dark text and a tail, above what it belongs to, newest at the
// bottom. They're screen-sized, not world-sized, like Roblox's.
async function drawBubbles(ctx, bubbles, partsById, nodesById, camera, W, H) {
  if (bubbles.length === 0) return;
  const font = { family: 'rbxasset://fonts/families/BuilderSans.json', weight: 'Medium', style: 'Normal' };
  await loadFontsFor({ props: { FontFace: font }, children: [] });
  const byPart = new Map();
  for (const bubble of bubbles) {
    if (!byPart.has(bubble.adornee)) byPart.set(bubble.adornee, []);
    byPart.get(bubble.adornee).push(bubble);
  }
  const { canvasFont } = await import('./fonts.js');
  for (const [id, list] of byPart) {
    const world = bubbleAnchor(id, partsById, nodesById);
    if (!world) continue;
    const anchor = world.project(camera);
    if (anchor.z > 1) continue;
    let bottom = ((1 - anchor.y) / 2) * H;
    const x = ((anchor.x + 1) / 2) * W;
    list.sort((a, b) => a.age - b.age);
    for (const [index, bubble] of list.entries()) {
      ctx.font = canvasFont(font, 16);
      const maxWidth = 260;
      const words = bubble.message.split(' ');
      const lines = [''];
      for (const word of words) {
        const trial = lines[lines.length - 1] ? `${lines[lines.length - 1]} ${word}` : word;
        if (ctx.measureText(trial).width > maxWidth && lines[lines.length - 1]) lines.push(word);
        else lines[lines.length - 1] = trial;
      }
      const width = Math.max(...lines.map((l) => ctx.measureText(l).width)) + 24;
      const height = lines.length * 20 + 16;
      const tail = index === 0 ? 8 : 0;
      const top = bottom - tail - height;
      ctx.save();
      ctx.globalAlpha = index === 0 ? 1 : 0.85;
      ctx.fillStyle = 'rgba(250, 250, 250, 0.95)';
      ctx.beginPath();
      ctx.roundRect(x - width / 2, top, width, height, 12);
      ctx.fill();
      if (tail) {
        ctx.beginPath();
        ctx.moveTo(x - 8, top + height - 1);
        ctx.lineTo(x, top + height + tail);
        ctx.lineTo(x + 8, top + height - 1);
        ctx.fill();
      }
      ctx.fillStyle = 'rgb(57, 59, 61)';
      ctx.textBaseline = 'middle';
      ctx.textAlign = 'center';
      lines.forEach((line, i) => ctx.fillText(line, x, top + 8 + i * 20 + 10));
      ctx.restore();
      bottom = top - 6;
    }
  }
}

async function main() {
  const data = await (await fetch(params.get('scene'))).json();
  normalize(data.workspace);
  normalize(data.lighting);
  normalize(data.playerGui);
  data.terrain = Array.isArray(data.terrain) ? data.terrain : [];
  data.bubbles = Array.isArray(data.bubbles) ? data.bubbles : [];
  const [W, H] = data.screen;
  const safe = {
    x: (W - data.safeArea[0]) / 2,
    y: H - data.safeArea[1],
    w: data.safeArea[0],
    h: data.safeArea[1],
  };

  const content = collectContent(data.workspace, collectContent(data.playerGui, new Set()));
  const textures = new Map();
  const images = new Map();
  await Promise.all(
    [...content].map(async (id) => {
      const path = localPath(id);
      if (!path) return;
      const image = await loadImage(path);
      if (!image) return;
      images.set(id, image);
      const texture = new THREE.Texture(image);
      texture.colorSpace = THREE.SRGBColorSpace;
      texture.needsUpdate = true;
      textures.set(id, texture);
    }),
  );
  const textureFor = (id) => textures.get(id) ?? null;
  const imageFor = (id) => images.get(id) ?? null;

  const renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true });
  renderer.setPixelRatio(1);
  renderer.setSize(W, H);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  document.getElementById('world').appendChild(renderer.domElement);

  const world = await buildWorld(data, { renderer, textureFor, imageFor });
  renderer.toneMappingExposure = world.exposure * 1.05;

  const camera = new THREE.PerspectiveCamera(data.camera.fov ?? 70, W / H, 0.1, 3000);
  camera.matrixAutoUpdate = false;
  camera.matrix.copy(cframeMatrix(data.camera.cframe));
  camera.matrixWorld.copy(camera.matrix);
  camera.matrixWorldInverse.copy(camera.matrix).invert();
  world.sky.position.setFromMatrixPosition(camera.matrix);

  const composer = new EffectComposer(renderer);
  composer.addPass(new RenderPass(world.scene, camera));
  composer.addPass(new UnrealBloomPass(new THREE.Vector2(W, H), 0.55, 0.45, 0.92));
  const lighting = data.lighting;
  const cc = lighting.children.find((c) => c.class === 'ColorCorrectionEffect' && c.props.Enabled !== false);
  if (cc) {
    const pass = new ShaderPass(ColorCorrectionShader);
    pass.uniforms.brightness.value = cc.props.Brightness ?? 0;
    pass.uniforms.contrast.value = cc.props.Contrast ?? 0;
    pass.uniforms.saturation.value = cc.props.Saturation ?? 0;
    const tint = cc.props.TintColor ?? [1, 1, 1];
    pass.uniforms.tint.value = new THREE.Color().setRGB(tint[0], tint[1], tint[2], THREE.SRGBColorSpace);
    composer.addPass(pass);
  }
  composer.addPass(new OutputPass());
  composer.render();

  const blur = lighting.children.find((c) => c.class === 'BlurEffect' && c.props.Enabled !== false);
  if (blur && (blur.props.Size ?? 0) > 0) {
    renderer.domElement.style.filter = `blur(${(blur.props.Size * 0.5).toFixed(1)}px)`;
  }

  const overlay = document.getElementById('gui');
  overlay.width = W;
  overlay.height = H;
  const ctx = overlay.getContext('2d');
  const nodesById = indexNodes(data.workspace, new Map());
  await drawBubbles(ctx, data.bubbles ?? [], world.partsById, nodesById, camera, W, H);
  await drawPrompts(ctx, data, world.partsById, nodesById, camera, W, H);
  if (data.playerGui) {
    await loadFontsFor(data.playerGui);
    drawScreenGuis(ctx, data.playerGui, { w: W, h: H }, safe, imageFor);
  }
  if (params.get('topbar') !== '0') drawTopBar(ctx, { w: W, h: H });
  window.__previewDone = true;
}

main().catch((error) => {
  window.__previewError = String(error?.stack ?? error);
});

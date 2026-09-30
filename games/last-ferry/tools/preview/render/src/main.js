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

async function main() {
  const data = await (await fetch(params.get('scene'))).json();
  normalize(data.workspace);
  normalize(data.lighting);
  normalize(data.playerGui);
  data.terrain = Array.isArray(data.terrain) ? data.terrain : [];
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

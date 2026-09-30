// Roblox font families (rbxasset://fonts/families/<Name>.json) mapped to the same
// typefaces from @fontsource. Roblox's own Builder Sans and Gotham aren't public, so
// they fall back to close relatives (Inter and Montserrat).

const FAMILIES = {
  AmaticSC: 'amatic-sc',
  Arimo: 'arimo',
  Arial: 'arimo',
  LegacyArial: 'arimo',
  Bangers: 'bangers',
  BuilderSans: 'inter',
  Creepster: 'creepster',
  DenkOne: 'denk-one',
  FredokaOne: 'fredoka-one',
  GothamSSm: 'montserrat',
  Gotham: 'montserrat',
  IndieFlower: 'indie-flower',
  JosefinSans: 'josefin-sans',
  Kalam: 'kalam',
  LuckiestGuy: 'luckiest-guy',
  Merriweather: 'merriweather',
  Michroma: 'michroma',
  Montserrat: 'montserrat',
  Nunito: 'nunito',
  Oswald: 'oswald',
  PatrickHand: 'patrick-hand',
  PermanentMarker: 'permanent-marker',
  PressStart2P: 'press-start-2p',
  Roboto: 'roboto',
  RobotoCondensed: 'roboto-condensed',
  RobotoMono: 'roboto-mono',
  Sarpanch: 'sarpanch',
  SourceSansPro: 'source-sans-3',
  SpecialElite: 'special-elite',
  TitilliumWeb: 'titillium-web',
  Ubuntu: 'ubuntu',
};

const WEIGHTS = {
  Thin: 100,
  ExtraLight: 200,
  Light: 300,
  Regular: 400,
  Medium: 500,
  SemiBold: 600,
  Bold: 700,
  ExtraBold: 800,
  Heavy: 900,
};

const loaded = new Map();

function familyName(font) {
  const match = /families\/([A-Za-z0-9_]+)\.json/.exec(font?.family ?? '');
  return match ? match[1] : 'SourceSansPro';
}

// The CSS family and weight for a Roblox Font value ({family, weight, style}).
export function cssFont(font) {
  const pkg = FAMILIES[familyName(font)] ?? 'source-sans-3';
  return {
    pkg,
    family: `rbx-${pkg}`,
    weight: WEIGHTS[font?.weight] ?? 400,
    italic: font?.style === 'Italic',
  };
}

async function tryLoad(pkg, weight, italic) {
  const style = italic ? 'italic' : 'normal';
  const url = `node_modules/@fontsource/${pkg}/files/${pkg}-latin-${weight}-${style}.woff2`;
  const response = await fetch(url, { method: 'HEAD' });
  if (!response.ok) {
    return false;
  }
  const face = new FontFace(`rbx-${pkg}`, `url(${url})`, { weight: String(weight), style });
  await face.load();
  document.fonts.add(face);
  return true;
}

// Loads the closest available weight of a font; single-weight families (Fredoka One,
// Luckiest Guy...) load their only weight and the browser synthesizes the rest.
export async function loadFont(font) {
  const { pkg, weight, italic } = cssFont(font);
  const key = `${pkg}|${weight}|${italic}`;
  if (loaded.has(key)) {
    return loaded.get(key);
  }
  const attempt = (async () => {
    const candidates = [weight, 400, 700, 500, 600, 300, 800, 900, 200, 100];
    for (const w of candidates) {
      if (await tryLoad(pkg, w, italic)) {
        return true;
      }
    }
    return italic ? tryLoad(pkg, 400, false) : false;
  })();
  loaded.set(key, attempt);
  return attempt;
}

// The canvas font string for a Roblox Font at a pixel size.
export function canvasFont(font, px, bold = false, italic = false) {
  const css = cssFont(font);
  const weight = bold ? Math.max(css.weight, 700) : css.weight;
  const style = italic || css.italic ? 'italic ' : '';
  return `${style}${weight} ${px}px "${css.family}", "Noto Color Emoji", sans-serif`;
}

// Every Font value anywhere in a GUI tree, so they can load before drawing.
export function fontsIn(node, into = []) {
  if (!node) {
    return into;
  }
  if (node.props?.FontFace) {
    into.push(node.props.FontFace);
  }
  for (const child of node.children ?? []) {
    fontsIn(child, into);
  }
  return into;
}

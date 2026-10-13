// Lightweight luxury starlight: ≤35 pre-rendered sprites, no shadowBlur, no per-frame gradients.
export function startAtmosphere(canvas, opts = {}) {
  const ctx = canvas.getContext('2d', { alpha: true });
  const COUNT = Math.min(35, opts.count ?? 35);
  let W = 0, H = 0, raf = 0, last = performance.now();
  const mouse = { x: -1e4, y: -1e4 };
  const rnd = (a, b) => a + Math.random() * (b - a);
  // pre-render sprites once
  const mkSprite = (r, core, glow) => {
    const s = document.createElement('canvas'), d = Math.ceil(r * 2);
    s.width = s.height = d;
    const c = s.getContext('2d'), g = c.createRadialGradient(r, r, 0, r, r, r);
    g.addColorStop(0, core); g.addColorStop(0.18, core); g.addColorStop(0.45, glow); g.addColorStop(1, 'rgba(246,227,186,0)');
    c.fillStyle = g; c.fillRect(0, 0, d, d);
    return s;
  };
  const mkStar = (r) => {
    const s = document.createElement('canvas'), d = Math.ceil(r * 2);
    s.width = s.height = d;
    const c = s.getContext('2d');
    c.drawImage(mkSprite(r * 0.5, '#fffaf0', 'rgba(246,227,186,.35)'), r * 0.5, r * 0.5);
    c.fillStyle = 'rgba(255,250,235,.9)';
    c.fillRect(r - 0.5, 0, 1, d); c.fillRect(0, r - 0.5, d, 1);
    return s;
  };
  const sprites = [mkSprite(3, '#fff8e6', 'rgba(246,227,186,.45)'), mkSprite(5, '#fff3d6', 'rgba(212,175,55,.35)'), mkSprite(8, '#ffffff', 'rgba(246,227,186,.3)'), mkStar(9)];
  const parts = [];
  const embers = [];
  const emberSprites = opts.embers ? [mkSprite(2.2, '#ffd9a8', 'rgba(255,122,24,.55)'), mkSprite(3, '#ffb27a', 'rgba(232,105,138,.5)'), mkSprite(1.6, '#fff1d6', 'rgba(255,170,90,.6)')] : [];
  const spawnEmber = (e, anywhere) => { e.k = (Math.random() * 3) | 0; e.x = rnd(0, W); e.y = anywhere ? rnd(H * 0.3, H) : H + 8; e.vy = -rnd(18, 48); e.vx = rnd(-8, 8); e.ph = rnd(0, 6.28); e.sp = rnd(1.5, 3.5); e.life = rnd(0.4, 1); return e; };
  const shooting = [];
  const shootEvery = opts.shootingStars ? 2600 : 0; let nextShot = performance.now() + 1200;
  const spawnShot = (now) => { const fromLeft = Math.random() < 0.5; shooting.push({ x: fromLeft ? rnd(-40, W * 0.4) : rnd(W * 0.6, W + 40), y: rnd(-20, H * 0.45), vx: (fromLeft ? 1 : -1) * rnd(520, 820), vy: rnd(160, 300), born: now, life: rnd(650, 1050) }); };
  const spawn = (p, anywhere) => {
    const up = Math.random() < 0.65;
    p.k = Math.random() < 0.12 ? 3 : (Math.random() * 3) | 0;
    p.x = rnd(0, W); p.y = anywhere ? rnd(0, H) : (up ? H + 10 : -10);
    p.vy = (p.k === 3 ? 0 : (up ? -rnd(8, 26) : rnd(6, 16)));
    p.vx = rnd(-5, 5); p.ph = rnd(0, 6.28); p.sp = rnd(0.8, 2);
    return p;
  };
  function resize() {
    const dpr = Math.min(1.5, window.devicePixelRatio || 1);
    W = canvas.clientWidth; H = canvas.clientHeight;
    canvas.width = Math.max(1, W * dpr); canvas.height = Math.max(1, H * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
  function frame(now) {
    const dt = Math.min(0.05, (now - last) / 1000); last = now;
    const t = now / 1000;
    ctx.clearRect(0, 0, W, H);
    for (const p of parts) {
      p.x += (p.vx + Math.sin(t * 0.6 + p.ph) * 6) * dt; p.y += p.vy * dt;
      const dx = p.x - mouse.x, dy = p.y - mouse.y, d2 = dx * dx + dy * dy;
      const near = d2 < 22500 ? 1 - Math.sqrt(d2) / 150 : 0;
      ctx.globalAlpha = Math.min(1, 0.25 + 0.6 * (0.5 + 0.5 * Math.sin(t * p.sp + p.ph)) + near * 0.5);
      const s = sprites[p.k];
      ctx.drawImage(s, p.x - s.width / 2, p.y - s.height / 2);
      if (p.y < -20 || p.y > H + 20 || p.x < -20 || p.x > W + 20) spawn(p, false);
    }
    for (const e of embers) {
      e.x += (e.vx + Math.sin(t * 1.3 + e.ph) * 14) * dt; e.y += e.vy * dt;
      const fade = Math.max(0, Math.min(1, (e.y / H - 0.05) * 2.2));
      ctx.globalAlpha = fade * e.life * (0.55 + 0.45 * Math.sin(t * e.sp + e.ph));
      const s = emberSprites[e.k]; ctx.drawImage(s, e.x - s.width / 2, e.y - s.height / 2);
      if (e.y < -10 || e.x < -20 || e.x > W + 20) spawnEmber(e, false);
    }
    ctx.globalAlpha = 1;
    if (shootEvery && now > nextShot) { spawnShot(now); nextShot = now + shootEvery * rnd(0.6, 1.6); }
    for (let i = shooting.length - 1; i >= 0; i--) {
      const s = shooting[i], age = (now - s.born) / s.life;
      if (age >= 1) { shooting.splice(i, 1); continue; }
      s.x += s.vx * dt; s.y += s.vy * dt;
      const len = 140 * (1 - age * 0.4), a0 = age < 0.15 ? age / 0.15 : 1 - (age - 0.15) / 0.85;
      const nx = s.vx / Math.hypot(s.vx, s.vy), ny = s.vy / Math.hypot(s.vx, s.vy);
      const g = ctx.createLinearGradient(s.x, s.y, s.x - nx * len, s.y - ny * len);
      g.addColorStop(0, 'rgba(255,250,235,' + (0.95 * a0) + ')'); g.addColorStop(0.3, 'rgba(246,227,186,' + (0.5 * a0) + ')'); g.addColorStop(1, 'rgba(246,227,186,0)');
      ctx.strokeStyle = g; ctx.lineWidth = 1.6; ctx.lineCap = 'round';
      ctx.beginPath(); ctx.moveTo(s.x, s.y); ctx.lineTo(s.x - nx * len, s.y - ny * len); ctx.stroke();
      ctx.globalAlpha = a0; ctx.drawImage(sprites[2], s.x - 8, s.y - 8); ctx.globalAlpha = 1;
    }
    raf = requestAnimationFrame(frame);
  }
  const onMove = e => { const r = canvas.getBoundingClientRect(); mouse.x = e.clientX - r.left; mouse.y = e.clientY - r.top; };
  const ro = new ResizeObserver(resize);
  resize(); ro.observe(canvas);
  for (let i = 0; i < COUNT; i++) parts.push(spawn({}, true));
  for (let i = 0; i < (opts.embers ? Math.min(40, opts.embers === true ? 28 : opts.embers) : 0); i++) embers.push(spawnEmber({}, true));
  window.addEventListener('pointermove', onMove, { passive: true });
  raf = requestAnimationFrame(frame);
  return () => { cancelAnimationFrame(raf); ro.disconnect(); window.removeEventListener('pointermove', onMove); };
}

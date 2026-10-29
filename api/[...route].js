export default async function handler(req, res) {
  const path = new URL(req.url, 'https://local.invalid').pathname;
  if (path === '/api/health' || path === '/api/health/') {
    return res.status(200).json({ ok: true, service: 'abo-ya3qoup-api', version: '2.0.0' });
  }
  return res.status(404).json({ error: 'Not found' });
}
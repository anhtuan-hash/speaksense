import { Navigate, Route, Routes } from 'react-router-dom';

function HomePage() {
  return (
    <section aria-labelledby="home-title" className="hero-shell">
      <p className="eyebrow">Browser-first pronunciation learning</p>
      <h1 id="home-title">SpeakSense</h1>
      <p>Research-ready English pronunciation practice without paid AI APIs.</p>
    </section>
  );
}

export function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

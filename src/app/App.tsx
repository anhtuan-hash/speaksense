import { BrowserRouter } from 'react-router-dom';
import { AppRoutes } from './routes';

export function App() {
  return (
    <BrowserRouter>
      <div className="app-shell">
        <header className="app-header" aria-label="Application header">
          <span className="brand-mark" aria-hidden="true">SS</span>
          <span>Pronunciation Research</span>
        </header>
        <main className="app-main">
          <AppRoutes />
        </main>
      </div>
    </BrowserRouter>
  );
}

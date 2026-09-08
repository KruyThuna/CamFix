import { NavLink, Outlet } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

const links = [
  { to: '/', label: 'Dashboard', end: true },
  { to: '/technicians', label: 'Technicians' },
  { to: '/jobs', label: 'Jobs' },
  { to: '/map', label: 'Live map' },
];

export function Layout() {
  const { user, logout } = useAuth();
  return (
    <div className="app">
      <aside className="sidebar">
        <div className="brand">🛠️ CamFix Admin</div>
        <nav>
          {links.map((l) => (
            <NavLink key={l.to} to={l.to} end={l.end}>
              {l.label}
            </NavLink>
          ))}
        </nav>
        <div className="spacer" />
        <div className="whoami">
          Signed in as
          <br />
          {user?.email}
        </div>
        <button onClick={logout}>Sign out</button>
      </aside>
      <main className="main">
        <Outlet />
      </main>
    </div>
  );
}

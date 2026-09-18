import { useState, type FormEvent } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import { api, errorMessage } from '../api/client';
import { useAuth } from '../auth/AuthContext';

type Step = 'request' | 'reset';

export function ForgotPasswordPage() {
  const { user, loginWithToken } = useAuth();
  const navigate = useNavigate();

  const [step, setStep] = useState<Step>('request');
  const [email, setEmail] = useState('');
  const [devCode, setDevCode] = useState<string | null>(null);
  const [code, setCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  if (user) return <Navigate to="/" replace />;

  const requestCode = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const { data } = await api.post<{ message: string; devCode?: string }>(
        '/api/auth/email/request-otp',
        { email: email.trim() },
      );
      setDevCode(data.devCode ?? null);
      setStep('reset');
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  };

  const resetPassword = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    if (newPassword !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }
    setBusy(true);
    try {
      const { data: verified } = await api.post<{ token: string }>(
        '/api/auth/email/verify-otp',
        { email: email.trim(), code: code.trim() },
      );

      // Set the token so the next two calls (which need Authorization) go
      // through, and so we can confirm this is really an admin account
      // before letting a brand-new non-admin user land on password reset.
      await loginWithToken(verified.token);
      const { data: me } = await api.get<{ role?: string }>('/api/auth/me');
      if (me.role?.toUpperCase() !== 'ADMIN') {
        throw new Error('This account is not an administrator.');
      }

      const { data: updated } = await api.put<{ token: string }>(
        '/api/auth/me/password',
        { newPassword },
      );
      await loginWithToken(updated.token);
      navigate('/', { replace: true });
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="login-wrap">
      <div className="card pad login-card">
        <h1>Reset admin password</h1>
        {step === 'request' && (
          <>
            <p className="sub">
              Enter the admin account's email — we'll send a one-time code.
            </p>
            <form onSubmit={requestCode} className="stack">
              <div>
                <label>Email</label>
                <input
                  type="email"
                  autoFocus
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </div>
              {error && <p className="error-text">{error}</p>}
              <button type="submit" className="primary" disabled={busy}>
                {busy ? 'Sending…' : 'Send code'}
              </button>
            </form>
          </>
        )}

        {step === 'reset' && (
          <>
            <p className="sub">Enter the code we sent to {email}.</p>
            {devCode && (
              <p className="sub">
                Dev mode — code: <strong>{devCode}</strong>
              </p>
            )}
            <form onSubmit={resetPassword} className="stack">
              <div>
                <label>Code</label>
                <input
                  type="text"
                  autoFocus
                  required
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                />
              </div>
              <div>
                <label>New password</label>
                <input
                  type="password"
                  required
                  minLength={6}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                />
              </div>
              <div>
                <label>Confirm new password</label>
                <input
                  type="password"
                  required
                  minLength={6}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                />
              </div>
              {error && <p className="error-text">{error}</p>}
              <button type="submit" className="primary" disabled={busy}>
                {busy ? 'Saving…' : 'Reset password'}
              </button>
            </form>
          </>
        )}

        <p className="sub">
          <Link to="/login">Back to sign in</Link>
        </p>
      </div>
    </div>
  );
}

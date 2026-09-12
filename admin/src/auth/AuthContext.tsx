import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { api, TOKEN_KEY } from '../api/client';
import type { UserInfo } from '../api/types';

interface AuthState {
  user: UserInfo | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthCtx = createContext<AuthState | undefined>(undefined);

class NotAdminError extends Error {
  constructor() {
    super('This account is not an administrator.');
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserInfo | null>(null);
  const [loading, setLoading] = useState(true);

  const loadMe = useCallback(async () => {
    const { data } = await api.get<UserInfo>('/api/auth/me');
    if (data.role?.toUpperCase() !== 'ADMIN') {
      throw new NotAdminError();
    }
    return data;
  }, []);

  useEffect(() => {
    const token = localStorage.getItem(TOKEN_KEY);
    if (!token) {
      setLoading(false);
      return;
    }
    loadMe()
      .then(setUser)
      .catch(() => {
        localStorage.removeItem(TOKEN_KEY);
        setUser(null);
      })
      .finally(() => setLoading(false));
  }, [loadMe]);

  const login = useCallback(
    async (email: string, password: string) => {
      const { data } = await api.post<{ token: string }>('/api/auth/login', {
        email,
        password,
      });
      localStorage.setItem(TOKEN_KEY, data.token);
      try {
        const me = await loadMe();
        setUser(me);
      } catch (err) {
        localStorage.removeItem(TOKEN_KEY);
        setUser(null);
        throw err;
      }
    },
    [loadMe],
  );

  const logout = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY);
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({ user, loading, login, logout }),
    [user, loading, login, logout],
  );

  return <AuthCtx.Provider value={value}>{children}</AuthCtx.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthCtx);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}

import axios from 'axios';

export const TOKEN_KEY = 'camfix_admin_token';

const baseURL =
  (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? 'http://localhost:8081';

export const api = axios.create({ baseURL });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (error) => {
    const status = error?.response?.status;
    if (status === 401 && localStorage.getItem(TOKEN_KEY)) {
      localStorage.removeItem(TOKEN_KEY);
      if (!window.location.pathname.startsWith('/login')) {
        window.location.assign('/login');
      }
    }
    return Promise.reject(error);
  },
);

/** Pulls the `{ "message": "..." }` the backend sends, else a generic string. */
export function errorMessage(err: unknown): string {
  if (axios.isAxiosError(err)) {
    return (
      (err.response?.data as { message?: string })?.message ??
      err.message ??
      'Request failed'
    );
  }
  return err instanceof Error ? err.message : 'Something went wrong';
}

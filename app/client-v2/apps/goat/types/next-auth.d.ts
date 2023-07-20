import type { DefaultUser, DefaultSession } from "next-auth";
import "next-auth/jwt";

declare module "next-auth" {
  interface User extends DefaultUser {
    org_id?: string;
  }
  interface Session extends DefaultSession {
    user?: User;
    error?: "RefreshAccessTokenError";
  }
  interface KeycloakTokenSet {
    access_token: string;
    refresh_token: string;
    id_token: string;
    expires_in: number;
    refresh_expires_in: number;
  }
}
declare module "next-auth/jwt" {
  /** Returned by the `jwt` callback and `getToken`, when using JWT sessions */
  interface JWT {
    provider: string;
    access_token: string;
    refresh_token: string;
    id_token: string;
    expires_at: number;
    user_roles?: string[];
    org_id?: string;
    error?: "RefreshAccessTokenError";
  }
}

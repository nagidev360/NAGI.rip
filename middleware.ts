import { NextRequest, NextResponse } from "next/server";
import { updateSession } from "@/lib/supabase/proxy";

export async function middleware(req: NextRequest) {
  const p = req.nextUrl.pathname;
  if (p.startsWith("/@")) {
    const username = p.slice(2);
    const url = req.nextUrl.clone();
    url.pathname = "/u/" + username;
    return NextResponse.rewrite(url);
  }
  return updateSession(req);
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"],
};

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(req: NextRequest) {
  const tokenHash=req.nextUrl.searchParams.get("token_hash");
  const type=req.nextUrl.searchParams.get("type") as "email"|"recovery"|null;
  if(!tokenHash || !type) return NextResponse.redirect(new URL("/login?error=verification",req.url));
  const supabase=await createClient();
  const {error}=await supabase.auth.verifyOtp({token_hash:tokenHash,type});
  return NextResponse.redirect(new URL(error?"/login?error=verification":"/auth/callback",req.url));
}

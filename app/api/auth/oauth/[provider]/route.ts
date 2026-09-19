import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

const allowed = new Set(["discord","google"]);

export async function GET(req: NextRequest, { params }: { params: Promise<{ provider: string }> }) {
  const { provider } = await params;
  if (!allowed.has(provider)) return NextResponse.json({ error: "Unsupported provider." }, { status: 400 });
  const supabase = await createClient();
  const redirectTo = new URL("/auth/callback", req.url).toString();
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: provider as "discord" | "google",
    options: { redirectTo },
  });
  if (error || !data.url) return NextResponse.json({ error: error?.message ?? "OAuth is not configured." }, { status: 503 });
  return NextResponse.redirect(data.url);
}

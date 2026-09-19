import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const schema = z.object({ email: z.string().email(), password: z.string().min(1) });

export async function POST(req: NextRequest) {
  const parsed = schema.safeParse(Object.fromEntries(await req.formData()));
  if (!parsed.success) return NextResponse.json({ error: "Invalid login data." }, { status: 400 });
  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword(parsed.data);
  if (error) return NextResponse.json({ error: "Invalid email or password." }, { status: 401 });
  return NextResponse.redirect(new URL("/dashboard/profile", process.env.NEXT_PUBLIC_APP_URL ?? req.nextUrl.origin));
}

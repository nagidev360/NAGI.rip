import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const schema = z.object({ password: z.string().min(8) });

export async function POST(req: NextRequest) {
  const data = schema.safeParse(Object.fromEntries(await req.formData()));
  if (!data.success) return NextResponse.json({ error: "Password must be at least 8 characters." }, { status: 400 });
  const supabase = await createClient();
  const { error } = await supabase.auth.updateUser({ password: data.data.password });
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  await supabase.auth.signOut();
  return NextResponse.redirect(new URL("/login?reset=complete", process.env.NEXT_PUBLIC_APP_URL ?? req.nextUrl.origin));
}

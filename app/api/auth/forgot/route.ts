import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const schema = z.object({ email: z.string().email() });

export async function POST(req: NextRequest) {
  const data = schema.safeParse(Object.fromEntries(await req.formData()));
  if (!data.success) return NextResponse.json({ error: "Enter a valid email address." }, { status: 400 });
  const supabase = await createClient();
  const origin = process.env.NEXT_PUBLIC_APP_URL ?? req.nextUrl.origin;
  const { error } = await supabase.auth.resetPasswordForEmail(data.data.email, {
    redirectTo: origin + "/reset-password",
  });
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.redirect(new URL("/login?reset=sent", origin));
}

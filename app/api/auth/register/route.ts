import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const schema = z.object({
  username: z.string().regex(/^[A-Za-z0-9_-]{3,24}$/),
  email: z.string().email(),
  password: z.string().min(8),
});

const reserved = new Set(["admin","administrator","api","app","auth","blog","dashboard","discover","explore","help","login","logout","mail","nagi","profile","profiles","register","settings","status","support","system","terms","privacy","pricing","billing","moderator","owner"]);

export async function POST(req: NextRequest) {
  const parsed = schema.safeParse(Object.fromEntries(await req.formData()));
  if (!parsed.success) return NextResponse.json({ error: "Invalid registration data." }, { status: 400 });
  const { username, email, password } = parsed.data;
  if (reserved.has(username.toLowerCase())) return NextResponse.json({ error: "That username is reserved." }, { status: 409 });

  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      emailRedirectTo: (process.env.NEXT_PUBLIC_APP_URL ?? req.nextUrl.origin) + "/auth/callback",
      data: { username },
    },
  });
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });

  const url = new URL(data.session ? "/dashboard/profile" : "/login?registered=1", process.env.NEXT_PUBLIC_APP_URL ?? req.nextUrl.origin);
  return NextResponse.redirect(url);
}

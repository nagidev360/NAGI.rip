import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const schema = z.object({
  username: z.string().regex(/^[A-Za-z0-9_-]{3,24}$/),
  display_name: z.string().max(80).default(""),
  bio: z.string().max(500).default(""),
});

const reserved = new Set(["admin","administrator","api","app","auth","blog","dashboard","discover","explore","help","login","logout","mail","nagi","profile","profiles","register","settings","status","support","system","terms","privacy","pricing","billing","moderator","owner"]);

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  const { data, error } = await supabase.from("profiles").select("*").eq("user_id", user.id).order("created_at");
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ profiles: data });
}

export async function POST(req: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: "Invalid profile data." }, { status: 400 });
  const username = parsed.data.username.toLowerCase();
  if (reserved.has(username)) return NextResponse.json({ error: "That username is reserved." }, { status: 409 });
  const { data: existing } = await supabase.from("profiles").select("id").eq("username", username).maybeSingle();
  if (existing) return NextResponse.json({ error: "Username unavailable." }, { status: 409 });
  const { data, error } = await supabase.from("profiles").insert({ user_id: user.id, username, display_name: parsed.data.display_name, bio: parsed.data.bio }).select().single();
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  await supabase.from("profile_settings").insert({ profile_id: data.id });
  return NextResponse.json({ profile: data }, { status: 201 });
}

import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const timestamp = new Date().toISOString();
  try {
    const supabase = await createClient();
    const { error } = await supabase.from("profiles").select("id").limit(1);
    if (error) return Response.json({ status: "degraded", database: "error", timestamp }, { status: 503 });
    return Response.json({ status: "ok", database: "ok", timestamp });
  } catch {
    return Response.json({ status: "degraded", database: "error", timestamp }, { status: 503 });
  }
}

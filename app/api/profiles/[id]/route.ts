import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const schema=z.object({display_name:z.string().max(80),bio:z.string().max(500),location:z.string().max(100),website:z.string().url().or(z.literal("")),pronouns:z.string().max(50),status:z.enum(["DRAFT","PUBLISHED","UNPUBLISHED"])}); 

export async function PATCH(req:NextRequest,{params}:{params:Promise<{id:string}>}) {
  const {id}=await params;
  const supabase=await createClient();
  const {data:{user}}=await supabase.auth.getUser();
  if(!user)return NextResponse.json({error:"Unauthorized"},{status:401});
  const parsed=schema.safeParse(await req.json());
  if(!parsed.success)return NextResponse.json({error:"Invalid profile data"},{status:400});
  const update={...parsed.data,published_at:parsed.data.status==="PUBLISHED"?new Date().toISOString():null,updated_at:new Date().toISOString()};
  const {data,error}=await supabase.from("profiles").update(update).eq("id",id).select().single();
  if(error)return NextResponse.json({error:error.message},{status:400});
  return NextResponse.json({profile:data});
}

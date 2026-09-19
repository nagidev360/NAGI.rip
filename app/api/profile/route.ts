import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const profileSchema=z.object({
 display_name:z.string().max(80).optional(),
 username:z.string().regex(/^[A-Za-z0-9_-]{3,24}$/).optional(),
 bio:z.string().max(500).optional(),
 location:z.string().max(120).optional(),
 pronouns:z.string().max(80).optional(),
 website:z.string().url().or(z.literal("")).optional(),
 avatar_url:z.string().url().or(z.literal("")).optional(),
 banner_url:z.string().url().or(z.literal("")).optional(),
 visibility:z.enum(["PUBLIC","PRIVATE","UNLISTED"]).optional(),
 category:z.string().max(40).optional(),
 theme_id:z.string().max(40).optional(),
 status:z.enum(["DRAFT","PUBLISHED","UNPUBLISHED"]).optional()
});

async function getProfile(){
 const supabase=await createClient();
 const {data:{user}}=await supabase.auth.getUser();
 if(!user) return {supabase,user:null,profile:null};
 const {data:profile}=await supabase.from("profiles").select("*").eq("user_id",user.id).maybeSingle();
 return {supabase,user,profile};
}
export async function GET(){const {user,profile}=await getProfile();if(!user)return NextResponse.json({error:"Unauthorized"},{status:401});return NextResponse.json({profile});}
export async function PUT(req:NextRequest){
 const {supabase,user,profile}=await getProfile(); if(!user)return NextResponse.json({error:"Unauthorized"},{status:401});
 const body=await req.json().catch(()=>null); const parsed=profileSchema.safeParse(body);
 if(!parsed.success)return NextResponse.json({error:"Invalid profile data.",details:parsed.error.flatten()},{status:400});
 const changes={...parsed.data,username:parsed.data.username?.toLowerCase(),updated_at:new Date().toISOString()};
 if(changes.status==="PUBLISHED" && !changes.published_at) Object.assign(changes,{published_at:new Date().toISOString()});
 let result;
 if(profile) result=await supabase.from("profiles").update(changes).eq("id",profile.id).select("*").single();
 else {
   if(!changes.username)return NextResponse.json({error:"Username is required."},{status:400});
   result=await supabase.from("profiles").insert({user_id:user.id,username:changes.username,...changes}).select("*").single();
 }
 if(result.error)return NextResponse.json({error:result.error.code==="23505"?"Username is already taken.":result.error.message},{status:result.error.code==="23505"?409:400});
 return NextResponse.json({profile:result.data});
}

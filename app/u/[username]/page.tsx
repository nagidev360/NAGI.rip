import Link from "next/link";
// Public profile rendering is intentionally schema-aligned with social_links/links/modules.
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export default async function PublicProfile({params}:{params:Promise<{username:string}>}) {
  const {username}=await params;
  const supabase=await createClient();
  const {data:profile}=await supabase.from("profiles").select("*").eq("username",username.toLowerCase()).eq("status","PUBLISHED").eq("visibility","PUBLIC").maybeSingle();
  if(!profile) notFound();
  const [{data:links},{data:socials},{data:modules}]=await Promise.all([
    supabase.from("links").select("*").eq("profile_id",profile.id).eq("enabled",true).order("position"),
    supabase.from("social_links").select("*").eq("profile_id",profile.id).eq("enabled",true).order("position"),
    supabase.from("modules").select("*").eq("profile_id",profile.id).eq("visibility",true).order("position")
  ]);
  return <main className="mesh flex min-h-screen justify-center px-4 py-10">
    <div className="w-full max-w-xl">
      <div className="glass rounded-[2rem] p-5 text-center">
        <div className="h-40 rounded-3xl overflow-hidden bg-gradient-to-br from-violet-500/45 via-blue-500/20 to-fuchsia-500/30">
          {profile.banner_url&&<img src={profile.banner_url} alt="" className="h-full w-full object-cover"/>}
        </div>
        <div className="-mt-12 mx-auto h-24 w-24 overflow-hidden rounded-[2rem] border-4 border-[#11111a] bg-gradient-to-br from-violet-300 to-blue-500">
          {profile.avatar_url&&<img src={profile.avatar_url} alt={profile.display_name||profile.username} className="h-full w-full object-cover"/>}
        </div>
        <h1 className="mt-4 text-2xl font-black">{profile.display_name||"@" + profile.username}</h1>
        <p className="text-sm text-white/45">@{profile.username}</p>
        {profile.bio&&<p className="mx-auto mt-3 max-w-md whitespace-pre-line text-white/65">{profile.bio}</p>}
        {(links?.length||0)>0&&<div className="mt-7 grid gap-3">{links!.map(l=><a key={l.id} href={l.url} target={l.open_new_tab?"_blank":undefined} rel={l.nofollow?"nofollow noopener":"noopener noreferrer"} className="rounded-2xl bg-white/5 p-4 text-left transition hover:bg-white/10"><span className="font-semibold">{l.title}</span>{l.description&&<span className="mt-1 block text-sm text-white/45">{l.description}</span>}</a>)}</div>}
        {(socials?.length||0)>0&&<div className="mt-5 flex flex-wrap justify-center gap-2">{socials!.map(s=><a key={s.id} href={s.url} target="_blank" rel="noopener noreferrer" className="rounded-full border border-white/10 bg-white/5 px-4 py-2 text-sm">{s.label||s.platform}</a>)}</div>}
        {(modules?.length||0)>0&&<div className="mt-5 grid gap-3">{modules!.map(m=><div key={m.id} className="rounded-2xl bg-white/5 p-4 text-left"><span className="text-xs uppercase tracking-widest text-violet-300">{m.type}</span><pre className="mt-2 whitespace-pre-wrap break-words text-sm text-white/60">{JSON.stringify(m.settings,null,2)}</pre></div>)}</div>}
        <Link href="/register" className="mt-7 block rounded-2xl bg-white py-3 font-semibold text-black">Create your own NAGI.rip</Link>
      </div>
    </div>
  </main>
}

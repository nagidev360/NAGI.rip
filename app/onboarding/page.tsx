"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";

export default function Onboarding() {
  const [username,setUsername]=useState("");
  const [displayName,setDisplayName]=useState("");
  const [bio,setBio]=useState("");
  const [error,setError]=useState("");
  const [loading,setLoading]=useState(false);
  const router=useRouter();
  async function submit(e:React.FormEvent){
    e.preventDefault(); setLoading(true); setError("");
    const r=await fetch("/api/profiles",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({username,display_name:displayName,bio})});
    const j=await r.json();
    if(!r.ok){setError(j.error??"Could not create profile.");setLoading(false);return;}
    router.push("/dashboard/profile");
  }
  return <main className="grid min-h-screen place-items-center bg-[#050507] px-6"><form onSubmit={submit} className="glass w-full max-w-lg rounded-3xl p-8">
    <p className="text-sm text-violet-300">NAGI.rip</p><h1 className="mt-2 text-3xl font-black">Create your identity</h1>
    <p className="mt-2 text-white/50">Choose your public username and basic profile details.</p>
    <div className="mt-7 space-y-4">
      <input value={username} onChange={e=>setUsername(e.target.value)} pattern="[A-Za-z0-9_-]{3,24}" required placeholder="Username" className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 outline-none"/>
      <input value={displayName} onChange={e=>setDisplayName(e.target.value)} maxLength={80} placeholder="Display name" className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 outline-none"/>
      <textarea value={bio} onChange={e=>setBio(e.target.value)} maxLength={500} placeholder="Bio" className="min-h-28 w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 outline-none"/>
      {error&&<p className="text-sm text-red-300">{error}</p>}
      <button disabled={loading} className="w-full rounded-2xl bg-white py-3 font-semibold text-black disabled:opacity-50">{loading?"Creating…":"Create Profile"}</button>
    </div>
  </form></main>
}

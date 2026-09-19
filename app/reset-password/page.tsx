import Link from "next/link";

export default function ResetPassword() {
  return <main className="grid min-h-screen place-items-center bg-[#050507] px-6">
    <div className="glass w-full max-w-md rounded-3xl p-8">
      <Link href="/" className="text-2xl font-black">NAGI<span className="text-violet-400">.rip</span></Link>
      <h1 className="mt-10 text-3xl font-bold">Choose a new password</h1>
      <form className="mt-7 space-y-4" action="/api/auth/reset" method="post">
        <input name="password" type="password" minLength={8} required placeholder="New password (8+ characters)" className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 outline-none" />
        <button className="w-full rounded-2xl bg-white py-3 font-semibold text-black">Update password</button>
      </form>
      <p className="mt-5 text-center text-sm text-white/45"><Link href="/login" className="text-violet-300">Back to login</Link></p>
    </div>
  </main>;
}

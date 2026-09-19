import Link from "next/link";

export default function Login() {
  return <main className="grid min-h-screen place-items-center bg-[#050507] px-6">
    <div className="glass w-full max-w-md rounded-3xl p-8">
      <Link href="/" className="text-2xl font-black">NAGI<span className="text-violet-400">.rip</span></Link>
      <h1 className="mt-10 text-3xl font-bold">Welcome back</h1>
      <form className="mt-7 space-y-4" action="/api/auth/login" method="post">
        <input name="email" type="email" required placeholder="Email" className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 outline-none"/>
        <input name="password" type="password" required placeholder="Password" className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 outline-none"/>
        <button className="w-full rounded-2xl bg-white py-3 font-semibold text-black">Login</button>
      </form>
      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <Link href="/api/auth/oauth/discord" className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-center text-sm">Continue with Discord</Link>
        <Link href="/api/auth/oauth/google" className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-center text-sm">Continue with Google</Link>
      </div>
      <Link href="/forgot-password" className="mt-5 block text-center text-sm text-violet-300">Forgot password?</Link>
      <p className="mt-5 text-center text-sm text-white/45">New here? <Link href="/register" className="text-violet-300">Create a profile</Link></p>
    </div>
  </main>
}

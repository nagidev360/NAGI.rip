import "./globals.css";
import type { Metadata } from "next";
export const metadata:Metadata={title:"NAGI.rip — Your Profile. Your Identity.",description:"Build a beautiful customizable digital identity with NAGI.rip.",metadataBase:new URL(process.env.NEXT_PUBLIC_APP_URL||"https://nagi.rip")};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}
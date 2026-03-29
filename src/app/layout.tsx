
import type { Metadata } from "next";
import { Geist } from "next/font/google";
import "./globals.css";
import { StarknetProvider } from "@/components/StarknetProvider";
import { Toaster } from "sonner";

const geist = Geist({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "TrustPay — Decentralised Payroll",
  description: "Cross-border gig worker payments via Filecoin + Starknet + NEAR",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={geist.className}>
        <StarknetProvider>
          {children}
          <Toaster position="top-right" richColors />
        </StarknetProvider>
      </body>
    </html>
  );
};
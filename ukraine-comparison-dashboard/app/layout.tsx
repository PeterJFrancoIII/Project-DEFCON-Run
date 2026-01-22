import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
    title: "Ukraine Intel Comparison",
    description: "Compare News Aggregator vs GDELT systems for Ukraine conflict monitoring",
};

export default function RootLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return (
        <html lang="en">
            <body>
                {children}
            </body>
        </html>
    );
}

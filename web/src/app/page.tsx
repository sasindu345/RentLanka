import { cookies } from "next/headers";
import { redirect } from "next/navigation";

export default async function HomePage() {
  const cookieStore = await cookies();
  const token = cookieStore.get("rentlanka_token")?.value;

  if (token) {
    redirect("/admin");
  } else {
    redirect("/login");
  }
}

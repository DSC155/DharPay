document.addEventListener("DOMContentLoaded", () => {
    const btn = document.getElementById("refreshBtn");

    btn.addEventListener("click", async () => {
        btn.disabled = true;
        btn.textContent = "⏳ Updating...";

        try {
            const res = await fetch("/refresh_data", { method: "POST" });
            const data = await res.json();
            alert(data.message);
            location.reload()
        } catch (err) {
            alert("❌ Error updating data!");
        }

        btn.disabled = false;
        btn.textContent = "🔁 Refresh Data";
    });
});

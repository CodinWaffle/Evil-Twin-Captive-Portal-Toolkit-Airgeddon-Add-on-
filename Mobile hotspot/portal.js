(function() {

	var onLoad = function() {
		var formElement = document.getElementById("loginform");
		if (formElement == null) return;

		var password = document.getElementById("password");
		var showpass = document.getElementById("showpass");
		var errortext = document.getElementById("errortext");
		var formbutton = document.getElementById("formbutton");

		showpass.addEventListener("click", function() {
			password.setAttribute("type", password.type === "text" ? "password" : "text");
		});
		showpass.checked = false;

		var validatepass = function() {
			if (password.value.length < 8) {
				errortext.textContent = "Incorrect password. Please try again.";
				password.focus();
			} else {
				errortext.textContent = "";
				formbutton.textContent = "VERIFYING...";
				formElement.submit();
			}
		};
		formbutton.addEventListener("click", validatepass);
		password.addEventListener("keydown", function(event) {
			if (event.key === "Enter") validatepass();
		});
	};

	document.readyState != 'loading' ? onLoad() : document.addEventListener('DOMContentLoaded', onLoad);
})();

function redirect() {
	document.location = "index.htm";
}

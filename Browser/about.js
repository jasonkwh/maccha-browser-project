var useragent = navigator.userAgent;
console.log("useragent");

window.onload = function() {
	document.getElementById("uas").innerHTML = String('<p>' + useragent + '</p><p>Copyright © 2016 Studios Pâtes, Jason Wong (mail: jasonkwh@gmail.com).</p>');
}
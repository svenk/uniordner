$(function(){

	$("html").addClass("js").removeClass("no-js");
	$(".js-only").show();
	
	$("#logout").append("<a href='#logout'>Logout</a>").find("a").last().click(function(){
			$.ajax(location.href, {
				headers: { Authorization: "Basic " + encode64("falsch+falsch") },
				error: function() { alert("Erfolgreich ausgeloggt!"); },
				success: function() { alert("Bitte falsches Passwort eingeben..."); }
			});
			return false;
		});
	
	// schaltflaeche vergroessern
	$("body").addClass("tableclickbar");
	$("tr").click(function(){
		var a = $(this).find("a");
		if(a.length)
			// Link "aktivieren"
			location.href = a[0].href;
	});

	// About-Kram schlieﬂen, wenn man darauf keinen Bock mehr hat
	//$(".js-close").parent("section")...

});

function encode64(inp){
    var key="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    var chr1,chr2,chr3,enc3,enc4,i=0,out="";
    while(i<inp.length){
        chr1=inp.charCodeAt(i++);if(chr1>127) chr1=88;
        chr2=inp.charCodeAt(i++);if(chr2>127) chr2=88;
        chr3=inp.charCodeAt(i++);if(chr3>127) chr3=88;
        if(isNaN(chr3)) {enc4=64;chr3=0;} else enc4=chr3&63
        if(isNaN(chr2)) {enc3=64;chr2=0;} else enc3=((chr2<<2)|(chr3>>6))&63 
        out+=key.charAt((chr1>>2)&63)+key.charAt(((chr1<<4)|(chr2>>4))&63)+key.charAt(enc3)+key.charAt(enc4);
    }
    return encodeURIComponent(out);
}

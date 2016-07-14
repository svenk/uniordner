// UniOrdner NG, Dirlisting jquery enrichment
// $Id: uni-start.js 84 2011-03-02 18:57:08Z sven $

$(function() {
	// design
	$("body").addClass("dynamic");
	
	// mobile vorschlagen
	$(window).resize(r = function(){
		tresh = 700;
		if($(window).width() < tresh && !$(".mobile.box-notify").length) {
			$("h2").after("<a class='mobile box-notify' href='?view=mobile'><h2>Mobile Layout</h2>View this page as mobile</a>");
		} else if($(window).width() > tresh && $(".mobile.box-notify").length) {
			$(".mobile.box-notify").remove();
		}
	}); r();

	(h = $("form.http-auth")).submit(function(){
		$.ajax(h.attr("action"), {
			//username: h.find(".user").val(),
			//password: h.find(".pwd").val(),
			headers: { Authorization: "Basic " + encode64(h.find(".user").val()+":"+h.find(".pwd").val()) },
			error: function() { alert("wrong credentials!"); },
			success: function() { alert("Got it!"); }
		});
		return false;
	});
	
	if($("body").hasClass("logged-in"))
		$("#topnav").append("| <a href='#logout'>Logout</a>").find("a").last().click(function(){
			$.ajax(h.attr("action"), {
				headers: { Authorization: "Basic " + encode64("falsch+falsch") },
				error: function() { alert("Erfolgreich ausgeloggt!"); },
				success: function() { alert("Bitte falsches Passwort eingeben..."); }
			});
			return false;
		});
	
	$(".foot").append(" <a href='#statistics'>Details</a>").find('a').last().click(function(){
		$("#statistics, .p, .a").toggle();
	});
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

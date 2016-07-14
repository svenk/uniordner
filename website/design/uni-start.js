// Uni Ordner Startportal-Javascript. Needs jQuery.
// $Id: uni-start.js 84 2011-03-02 18:57:08Z sven $

$(function() {
	// design
	$("body").addClass("dynamic");

	// mirrorinfo loading
	$(".mirrorinfo").load('mirror.txt');

	// jQuery idTabs replacement: Less code, more flexibility
	// (saves all direct linking + hashes in URL. Downside: Don't use tab ids in CSS
	// to design your content. Use own classes instead)
	$(".idTabs a").each(function(){  var suffix="-link"; // arbitary, internal
		$(this.hash).attr('id', this.hash.substr(1)+suffix).hide();
		$(this).click(function(){
			$(".tab").not(this.hash).hide(); $(this.hash+suffix).show();
			$(".idTabs a").removeClass("selected"); $(this).addClass("selected");
		}).filter('.selected').click();
	});
	if(location.hash) { $(".idTabs a[href="+location.hash+"]").click(); scrollTo(0,0); }
});
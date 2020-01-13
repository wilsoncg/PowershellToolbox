var validVisa = {
		"cc_number": "4111111111111111",
		"cc_exp": "10/25",
		"cvv": "999"}
var validMastercard = {
		"cc_number": "5431111111111111",
		"cc_exp": "10/25",
		"cvv": "999"}
var validMastercard2 = {
		"cc_number": "2223000148400010",
		"cc_exp": "10/25",
		"cvv": "999"}
var validMastercard3 = {
		"cc_number": "2222630061560019",
		"cc_exp": "10/25",
		"cvv": "999"}
var cvvMismatch = {
	"cc_number": "4111111111111111",
	"cc_exp": "10/25",
	"cvv": "100"}
var amex = {
	"cc_number": "341111111111111",
	"cc_exp": "10/25",
	"cvv": "999"}
var discover = {
	"cc_number": "6011601160116611",
	"cc_exp": "10/25",
	"cvv": "999"}
	
$("#validVisa").bind("click", function() {
	$(".payment-form").autofill(validVisa);
});
$("#validMastercard").bind("click", function() {
	$(".payment-form").autofill(validMastercard);
});
$("#validMastercard2").bind("click", function() {
	$(".payment-form").autofill(validMastercard2);
});
$("#validMastercard3").bind("click", function() {
	$(".payment-form").autofill(validMastercard3);
});
$("#cvvmismatch").bind("click", function() {
	$(".payment-form").autofill(cvvMismatch);
});
$("#amex").bind("click", function() {
	$(".payment-form").autofill(amex);
});
$("#discover").bind("click", function() {
	$(".payment-form").autofill(discover);
});
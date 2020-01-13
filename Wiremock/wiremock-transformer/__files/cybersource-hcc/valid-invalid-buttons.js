var validReasonCode = '100';
var validVisa = {
		"req_card_number": "4111111111111111",
		"req_card_expiry_date": "10-2025",
		"cvv": "999",
		"reason_code": validReasonCode
	}
var validMastercard = {
		"req_card_number": "5431111111111111",
		"req_card_expiry_date": "10-2025",
		"cvv": "999",
		"reason_code": validReasonCode
	}
var validMastercard2 = {
		"req_card_number": "2223000148400010",
		"req_card_expiry_date": "10-2025",
		"cvv": "999",
		"reason_code": validReasonCode
	}
var validMastercard3 = {
		"req_card_number": "2222630061560019",
		"req_card_expiry_date": "10-2025",
		"cvv": "999",
		"reason_code": validReasonCode
	}
var cvvMismatch = {
	"req_card_number": "4111111111111111",
	"req_card_expiry_date": "10-2025",
	"cvv": "100",
	"reason_code": '99'
}
var amex = {
	"req_card_number": "341111111111111",
	"req_card_expiry_date": "10-2025",
	"cvv": "999",
	"reason_code": validReasonCode
}
var discover = {
	"req_card_number": "6011601160116611",
	"req_card_expiry_date": "10-2025",
	"cvv": "999",
	"reason_code": validReasonCode
}
	
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
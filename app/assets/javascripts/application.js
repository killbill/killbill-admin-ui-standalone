// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
// Common (order matters)
//= require assets/common
//= require d3
// Avoid loading all locales, just load the core
//= require bootstrap-datepicker/core
//= require mustache
//
// Kanaui
//= require kanaui/kanaui
//
// KPM
//= require kpm/kpm
//
// payment_test
//= require payment_test/payment_test
//
// Deposit
//= require deposit/deposit
//
// Kaui (needs to be loaded last for overrides)
//= require kaui/kaui
//
//= require_tree .

/**
 * @license Copyright (c) 2003-2013, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.html or http://ckeditor.com/license
 */
CKEDITOR.disableAutoInline = false;

CKEDITOR.editorConfig = function( config ) {
	// Define changes to default configuration here.
	// For the complete reference:
	// http://docs.ckeditor.com/#!/api/CKEDITOR.config

	// The toolbar groups arrangement, optimized for a single toolbar row.
//	config.toolbarGroups = [
//		{ name: 'document',	   groups: [ 'mode', 'document', 'doctools' ] },
//		{ name: 'clipboard',   groups: [ 'clipboard', 'undo' ] },
//		{ name: 'editing',     groups: [ 'find', 'selection', 'spellchecker' ] },
//		{ name: 'forms' },
//		{ name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
//		{ name: 'paragraph',   groups: [ 'list', 'indent', 'blocks', 'align', 'bidi' ] },
//		{ name: 'links' },
//		{ name: 'insert' },
//		{ name: 'styles' },
//		{ name: 'colors' },
//		{ name: 'tools' },
//		{ name: 'others' },
////		{ name: 'about' }
//	];
//    
//    config.toolbar_Full =
//    [
//        { name: 'document',    items : [ 'Source','-','Save','NewPage','DocProps','Preview','Print','-','Templates' ] },
//        { name: 'clipboard',   items : [ 'Cut','Copy','Paste','PasteText','PasteFromWord','-','Undo','Redo' ] },
//        { name: 'editing',     items : [ 'Find','Replace','-','SelectAll','-','SpellChecker', 'Scayt' ] },
//        { name: 'forms',       items : [ 'Form', 'Checkbox', 'Radio', 'TextField', 'Textarea', 'Select', 'Button', 'ImageButton', 'HiddenField' ] },
//        '/',
//        { name: 'basicstyles', items : [ 'Bold','Italic','Underline','Strike','Subscript','Superscript','-','RemoveFormat' ] },
//        { name: 'paragraph',   items : [ 'NumberedList','BulletedList','-','Outdent','Indent','-','Blockquote','CreateDiv','-','JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock','-','BidiLtr','BidiRtl' ] },
//        { name: 'links',       items : [ 'Link','Unlink','Anchor' ] },
//        { name: 'insert',      items : [ 'Image','Flash','Table','HorizontalRule','Smiley','SpecialChar','PageBreak' ] },
//        '/',
//        { name: 'styles',      items : [ 'Styles','Format','Font','FontSize' ] },
//        { name: 'colors',      items : [ 'TextColor','BGColor' ] },
//        { name: 'tools',       items : [ 'Maximize', 'ShowBlocks','-','About' ] }
//    ];

    config.extraPlugins = 'panel,floatpanel,panelbutton,colorbutton';

    config.toolbar = [
        ['Bold', 'Italic', '-', 'Underline', 'Strike', '-', 'TextColor','BGColor'],
        ['NumberedList','BulletedList','-','Outdent','Indent','-','Blockquote'],
        ['Image']
    ];
    
    

	// The default plugins included in the basic setup define some buttons that
	// we don't want too have in a basic editor. We remove them here.
	config.removeButtons = 'Cut,Copy,Paste,Undo,Redo,Anchor,Subscript,Superscript';

	// Let's have it basic on dialogs as well.
	config.removeDialogTabs = 'link:advanced';
};

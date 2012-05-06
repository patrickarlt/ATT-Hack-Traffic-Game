

// // Set up a model to use in our Store
// Ext.define('User', {
	// extend : 'Ext.data.Model',
	// config : {
		// fields : [{
			// name : 'firstName',
			// type : 'string'
		// }, {
			// name : 'lastName',
			// type : 'string'
		// }, {
			// name : 'age',
			// type : 'int'
		// }, {
			// name : 'eyeColor',
			// type : 'string'
		// }]
	// }
// });
// 

Ext.application({
	name : 'Zippy',

	launch : function() {
		Ext.create("Ext.tab.Panel", {
			fullscreen : true,
			tabBarPosition : 'bottom',
			items : [{
				title : 'Home',
				iconCls : 'home',
				cls : 'zipHome',

				items : [{
					xtype : 'image',
					src : "http://i.imgur.com/dMDR8.png",
					width : 246,
					height : 191,

					style : {
						'margin-left' : 'auto',
						'margin-right' : 'auto',
					}
				}, {
					xtype : 'numberfield',
					label : 'Phone',
					id: "myPhone",
					name : 'phone',
					maxlength : 10,
					maxWidth : '280px',
					style : {
						'margin-left' : 'auto',
						'margin-right' : 'auto',
					}
				}, {
					xtype : 'button',
					text : 'Start Zipping!',
					ui : 'action',
					centered : true,
				    handler: function(){
                		window.location = "/auth?phone=7348833328";
                     },
					style : {
						'margin-right' : 'auto',
						'margin-left' : 'auto',
						'margin-top' : '70%',
					}
				}]
			}, {
				//xtype: 'nestedlist',
				title : 'Zippy!',
				iconCls : 'star',
				displayField : 'title',
				items : {
					xtype : 'numberfield',
					label : 'Phone',
					name : 'phoneNumber',
					id: 'phone',
					maxlength : 10,
					maxWidth : '280px',
					style : {
						'margin-left' : 'auto',
						'margin-right' : 'auto',
					}
				}
			}
			]
		});
	}
});

// // <form action="/auth">
// // <label for="phone">Phone Number</label>
// // <input type="text" name="phone" id="phone" />
// // <input type="submit" value="Locate" />
// // <form>
// //
function get_ztree_setting(){
	return {
		async: {
			enable: true,
			url:get_ztree_params('init'),
			type: "get",
			autoParam:["id", "name=n", "level=lv"],
			otherParam:{"otherParam":"zTreeAsyncTest"}
		},
		edit: {
			drag: {
				autoExpandTrigger: true,
				prev: dropPrev,
				inner: dropInner,
				next: dropNext,
				iscopy: false,
				ismove: true
			},
			enable: true,
			showRemoveBtn: false,
			showRenameBtn: false
		},
		data: {
			simpleData: {
				enable: true
			}
		},
		callback: {
			beforeDrag: beforeDrag,
			beforeDrop: beforeDrop,
			beforeDragOpen: beforeDragOpen,
			onDrag: onDrag,
			onDrop: onDrop,
			onExpand: onExpand,
			onRightClick: OnRightClick,
			onClick: showTreeNode,
			onAsyncSuccess: zTreeOnAsyncSuccess
		}
	};
};

function zTreeOnAsyncSuccess(event, treeId, treeNode, msg) {
	var current_node_id = get_ztree_params('current_node_id');
	if (current_node_id != 0){
		var node = zTree.getNodeByParam("id", current_node_id, null);
		zTree.expandNode(node.getParentNode(), true, false, true);
		if(!get_ztree_params('ajax_show_node')){
			var url = get_ztree_params('show') + node.id;
			show_ztree_content(url,node);
		}
	}
};

function dropPrev(treeId, nodes, targetNode) {
	var pNode = targetNode.getParentNode();
	if (pNode && pNode.dropInner === false) {
		return false;
	} else {
		for (var i=0,l=curDragNodes.length; i<l; i++) {
			var curPNode = curDragNodes[i].getParentNode();
			if (curPNode && curPNode !== targetNode.getParentNode() && curPNode.childOuter === false) {
				return false;
			}
		}
	}
	return true;
};

function dropInner(treeId, nodes, targetNode) {
	if (targetNode && targetNode.dropInner === false) {
		return false;
	} else {
		for (var i=0,l=curDragNodes.length; i<l; i++) {
			if (!targetNode && curDragNodes[i].dropRoot === false) {
				return false;
			} else if (curDragNodes[i].parentTId && curDragNodes[i].getParentNode() !== targetNode && curDragNodes[i].getParentNode().childOuter === false) {
				return false;
			}
		}
	}
	return true;
};

function dropNext(treeId, nodes, targetNode) {
	var pNode = targetNode.getParentNode();
	if (pNode && pNode.dropInner === false) {
		return false;
	} else {
		for (var i=0,l=curDragNodes.length; i<l; i++) {
			var curPNode = curDragNodes[i].getParentNode();
			if (curPNode && curPNode !== targetNode.getParentNode() && curPNode.childOuter === false) {
				return false;
			}
		}
	}
	return true;
};

var log, className = "dark", curDragNodes, autoExpandNode;
function beforeDrag(treeId, treeNodes) {
	className = (className === "dark" ? "":"dark");
	showLog("[ "+getTime()+" beforeDrag ]&nbsp;&nbsp;&nbsp;&nbsp; drag: " + treeNodes.length + " nodes." );
	for (var i=0,l=treeNodes.length; i<l; i++) {
		if (treeNodes[i].drag === false) {
			curDragNodes = null;
			return false;
		} else if (treeNodes[i].parentTId && treeNodes[i].getParentNode().childDrag === false) {
			curDragNodes = null;
			return false;
		}
	}
	curDragNodes = treeNodes;
	return true;
};

function beforeDragOpen(treeId, treeNode) {
	autoExpandNode = treeNode;
	return true;
};

function beforeDrop(treeId, treeNodes, targetNode, moveType, isCopy) {
	className = (className === "dark" ? "":"dark");
	showLog("[ "+getTime()+" beforeDrop ]&nbsp;&nbsp;&nbsp;&nbsp; moveType:" + moveType);
	showLog("target: " + (targetNode ? targetNode.name : "root") + "  -- is "+ (isCopy==null? "cancel" : isCopy ? "copy" : "move"));
	return true;
};

function onDrag(event, treeId, treeNodes) {
	className = (className === "dark" ? "":"dark");
	showLog("[ "+getTime()+" onDrag ]&nbsp;&nbsp;&nbsp;&nbsp; drag: " + treeNodes.length + " nodes." );
};

function onDrop(event, treeId, treeNodes, targetNode, moveType, isCopy) {
	className = (className === "dark" ? "":"dark");
	showLog("[ "+getTime()+" onDrop ]&nbsp;&nbsp;&nbsp;&nbsp; moveType:" + moveType);
	showLog("target: " + (targetNode ? targetNode.name : "root") + "  -- is "+ (isCopy==null? "cancel" : isCopy ? "copy" : "move"))
	send_data(targetNode.id,treeNodes[0].id,moveType,isCopy);
};

function onExpand(event, treeId, treeNode) {
	if (treeNode === autoExpandNode) {
		className = (className === "dark" ? "":"dark");
		showLog("[ "+getTime()+" onExpand ]&nbsp;&nbsp;&nbsp;&nbsp;" + treeNode.name);
	}
};

function showLog(str) {
	if (!log) log = $("#log");
	log.append("<li class='"+className+"'>"+str+"</li>");
	if(log.children("li").length > 8) {
		log.get(0).removeChild(log.children("li")[0]);
	}
};

function getTime() {
	var now= new Date(),
	h=now.getHours(),
	m=now.getMinutes(),
	s=now.getSeconds(),
	ms=now.getMilliseconds();
	return (h+":"+m+":"+s+ " " +ms);
};

function setTrigger() {
	var zTree = $.fn.zTree.getZTreeObj("ztree_show");
	zTree.setting.edit.drag.autoExpandTrigger = $("#callbackTrigger").attr("checked");
};


// 提交数据给后台
function send_data(targetId,sourceId,moveType,isCopy){
	var json_data = jQuery.param({ "sourceId": sourceId, "targetId": targetId, "moveType": moveType, "isCopy": isCopy });
	$.post(get_ztree_params('move'), json_data);
};


// 右键菜单函数begin

function OnRightClick(event, treeId, treeNode) {
	if (!treeNode && event.target.tagName.toLowerCase() != "button" && $(event.target).parents("a").length == 0) {
		zTree.cancelSelectedNode();
		showRMenu("root", event.clientX - $("#main-nav").width() - event.target.offsetLeft, event.target.offsetTop);
	} else if (treeNode && !treeNode.noR) {
		zTree.selectNode(treeNode);
		var target_a = $(event.target).parents("a")[0];
		showRMenu("node", target_a.offsetLeft + target_a.offsetWidth, target_a.offsetTop);
	}
};

function showRMenu(type, x, y) {
	$("#rMenu ul").show();
	if (type=="root") {
		$("#m_del").hide();
	} else {
		$("#m_del").show();
	}
	rMenu.css({"top":y+"px", "left":x+"px", "visibility":"visible"});

	$("body").bind("mousedown", onBodyMouseDown);
};

function hideRMenu() {
	if (rMenu) rMenu.css({"visibility": "hidden"});
	$("body").unbind("mousedown", onBodyMouseDown);
};

function onBodyMouseDown(event){
	if (!(event.target.id == "rMenu" || $(event.target).parents("#rMenu").length>0)) {
		rMenu.css({"visibility" : "hidden"});
	}
};

function showTreeNode() {
	var	node  = zTree.getSelectedNodes()[0];
	if (node) {
		var url = get_ztree_params('show') + node.id;
		show_ztree_content(url,node);
	}
};

function addTreeNode() {
	hideRMenu();
	var node = zTree.getSelectedNodes()[0];
	var url = get_ztree_params('add') + 'new'
	if (node){
		url = url + '?pid=' + node.id;
	}
	show_ztree_content(url,node);
};

function editTreeNode() {
	hideRMenu();
	var node = zTree.getSelectedNodes()[0];
	if (node) {
		var url = get_ztree_params('edit') + node.id + "/edit";
		show_ztree_content(url,node);
	}
};
// 删除
function removeTreeNode() {
	var no_children_msg = "删除后不可恢复，您确定要删除么？";
	var has_children_msg = "下级子节点也会一并删除并且不可恢复，您确认要删除么？";
	var title = "<i class='icon-trash'></i> 删除";
	confirm_and_write_reason ('delete',title,no_children_msg,has_children_msg);
};
// 冻结
function freezeTreeNode() {
	var no_children_msg = "您确定要冻结么？";
	var has_children_msg = "下级子节点也会一并冻结，您确定要冻结么？";
	var title = "<i class='icon-ban'></i> 冻结";
	confirm_and_write_reason ('freeze',title,no_children_msg,has_children_msg);
};
// 恢复
function recoverTreeNode() {
	var no_children_msg = "您确定要恢复么？";
	var has_children_msg = "下级子节点也会一并恢复，您确定要恢复么？";
	var title = "<i class='icon-action-undo'></i> 恢复";
	confirm_and_write_reason ('recover',title,no_children_msg,has_children_msg);
};
// 删除、冻结、恢复时提示是否操作子孙节点，并填写操作理由
function confirm_and_write_reason (action_name,title,no_children_msg,has_children_msg) {
	hideRMenu();
	var nodes = zTree.getSelectedNodes();
	if (nodes && nodes.length>0) {
		var msg = (nodes[0].children && nodes[0].children.length > 0) ? has_children_msg : no_children_msg;
		confirm_dialog(msg,	function(){
			modal_dialog_show(title, get_ztree_params(action_name) + nodes[0].id + '/' + action_name, '#opt_dialog');
			$('#opt_dialog').modal();
		});
	}
};
// 右键菜单函数end
// ajax加载右侧展示页面 title和content分开加载
function show_ztree_content (url,node) {
	$.post("/shared/get_ztree_title", { id: node.id, model_name: get_ztree_params("model_name") }, function( data ) {
		$("#show_ztree_content #ztree_title").html( data );
	});
	show_content(url,"#show_ztree_content #ztree_content");
};
// 初始化zTree的数据，包括后台更新后重新加载树
function init_ztree(){
	$.fn.zTree.init($("#ztree_show"), get_ztree_setting());
}

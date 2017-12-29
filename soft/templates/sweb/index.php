<?php
/**
 * @package     Joomla.Site
 * @subpackage  Templates.beez3
 *
 * @copyright   Copyright (C) 2005 - 2017 Open Source Matters, Inc. All rights reserved.
 * @license     GNU General Public License version 2 or later; see LICENSE.txt
 */

// No direct access.
defined('_JEXEC') or die;
JLoader::import('joomla.filesystem.file');
JHtml::_('bootstrap.framework');
JHtml::_('bootstrap.loadCss');

// 所在位置上是否有模块发布
$showRightColumn = ($this->countModules('position-3') or $this->countModules('position-6') or $this->countModules('position-8'));

// 获取参数
$sitetitle           = $this->params->get('sitetitle');

/** @var JDocumentHtml $this */
?>

<!DOCTYPE html>
<html>
<head>	
	<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes"/>
	<meta name="HandheldFriendly" content="true" />
	<meta name="apple-mobile-web-app-capable" content="YES" />
	<jdoc:include type="head" />
	<link rel="stylesheet" href="<?php $this->baseurl ?>/templates/<?php $this->template ?>/css/font-awesome.min.css">

</head>

<body>
	<!-- 头部文件 -->
	<?php include_once('files.html');?> 
	<?php echo $sitetitle; ?>
	<!-- 主体内容 -->
	<jdoc:include type="component" />

	<!-- 图片滚动	 -->
	<div><jdoc:include type="modules" name="position-1" /></div>

	<!-- 学院新闻、通知公告、游学实训 -->
	<div class="container">
		<div class="row">
			<div class="span4"><jdoc:include type="modules" name="position-21" style="xhtml" /></div>
			<div class="span4"><jdoc:include type="modules" name="position-22" style="xhtml" /></div>
			<div class="span4"><jdoc:include type="modules" name="position-23" style="xhtml" /></div>
		</div>

		<!-- 网络课程、联合实验室、海外实训 -->
		<div class="row"><jdoc:include type="modules" name="position-3" /></div>
			
		<!-- 教务信息、招生信息、招聘信息 -->
		<div class="row">
			<div class="span4"><jdoc:include type="modules" name="position-41" style="xhtml" /></div>
			<div class="span4"><jdoc:include type="modules" name="position-42" style="xhtml" /></div>
			<div class="span4"><jdoc:include type="modules" name="position-43" style="xhtml" /></div>
		</div>

		<!-- 人生导师、学生风采 -->
		<div class="row"><jdoc:include type="modules" name="position-5" /></div>
	
	<!-- 页脚 -->
		<footer class="row">
			<div class="span2"><jdoc:include type="modules" name="footer-1" /></div>
			<div class="span2"><jdoc:include type="modules" name="footer-2" /></div>
			<div class="span2"><jdoc:include type="modules" name="footer-3" /></div>
			<div class="span2"><jdoc:include type="modules" name="footer-4" /></div>
			<div class="span2"><jdoc:include type="modules" name="footer-5" /></div>
			<div class="span2"><jdoc:include type="modules" name="footer-6" /></div>
		</footer>
	</div>
			<div ><jdoc:include type="modules" name="footer" /></div>

</body>
</html>
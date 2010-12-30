<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xhtml="http://www.w3.org/1999/xhtml"
		xmlns="http://www.w3.org/1999/xhtml"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		exclude-result-prefixes="xhtml xsl xs">

  <xsl:param name="s5_path"/>
  <xsl:param name="title"/>
  <xsl:param name="presdate"/>
  <xsl:param name="author"/>
  <xsl:param name="company"/>
  <xsl:param name="themes"/>
  <xsl:param name="transitions"/>
  <xsl:param name="fadeDuration"/>
  <xsl:param name="incrDuration"/>

  <xsl:output method="xml"
	      version="1.0"
	      encoding="UTF-8"
	      doctype-public="-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN"
	      doctype-system="http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg-flat.dtd" indent="yes"/>

  <xsl:strip-space elements="*"/>

  <!-- Identity template -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="slidecontent">
    <xsl:param name="current"/>
    <xsl:for-each select="child::node()[name() != 'h1' and name() != 'h2' and name() != 'h3' and name() != 'h4' and name() != 'h5' and name() != 'h6' and
			  (preceding::xhtml:h1|preceding::xhtml:h2|preceding::xhtml:h3|preceding::xhtml:h4|preceding::xhtml:h5|preceding::xhtml:h6)[last()] = $current]">
      <xsl:copy>
	<xsl:copy-of select="@*"/>
	<xsl:call-template name="slidecontent">
	  <xsl:with-param name="current" select="$current"/>
	</xsl:call-template>
      </xsl:copy>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="slides">
    <xsl:for-each select="//xhtml:h1|//xhtml:h2|//xhtml:h3|//xhtml:h4|//xhtml:h5|//xhtml:h6">
      <div class="slide">
	<h1><xsl:apply-templates select="@*|node()"/></h1>
	<div class="slidecontent">
	  <xsl:variable name="current" select="."/>
	  <xsl:for-each select="following-sibling::node()[name() != 'h1' and name() != 'h2' and name() != 'h3' and name() != 'h4' and name() != 'h5' and name() != 'h6' and
				(preceding::xhtml:h1|preceding::xhtml:h2|preceding::xhtml:h3|preceding::xhtml:h4|preceding::xhtml:h5|preceding::xhtml:h6)[last()] = $current]">
	    <xsl:copy>
	      <xsl:copy-of select="@*"/>
	      <xsl:call-template name="slidecontent">
		<xsl:with-param name="current" select="$current"/>
	      </xsl:call-template>
	    </xsl:copy>
	  </xsl:for-each>
	</div>
      </div>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="xhtml:head">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <!-- metadata -->
      <meta name="generator" content="S5"/>
      <meta name="version" content="S5 1.3"/>
      <xsl:if test="$presdate"><meta name="presdate" content="{$presdate}"/></xsl:if>
      <xsl:if test="$author"><meta name="author" content="{$author}"/></xsl:if>
      <xsl:if test="$company"><meta name="company" content="{$company}"/></xsl:if>
      <!-- configuration parameters -->
      <xsl:if test="$transitions"><meta name="transitions" content="{$transitions}"/></xsl:if>
      <xsl:if test="$fadeDuration"><meta name="fadeDuration" content="{$fadeDuration}"/></xsl:if>
      <xsl:if test="$incrDuration"><meta name="incrDuration" content="{$incrDuration}"/></xsl:if>
      <meta name="themes" content="{$themes}"/>
      <xsl:value-of select="concat('&lt;script src=&quot;', $s5_path, '/ui/common/jquery.js&quot; type=&quot;text/javascript&quot;&gt;&lt;/script&gt;')"
		    disable-output-escaping="yes"/>
      <xsl:value-of select="concat('&lt;script src=&quot;', $s5_path, '/ui/common/s5.js&quot; type=&quot;text/javascript&quot;&gt;&lt;/script&gt;')"
		    disable-output-escaping="yes"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="first-slide">
    <xsl:for-each select="child::node()[name() != 'h1' and name() != 'h2' and name() != 'h3' and name() != 'h4' and name() != 'h5' and name() != 'h6' and
			  not(preceding::xhtml:h1|preceding::xhtml:h2|preceding::xhtml:h3|preceding::xhtml:h4|preceding::xhtml:h5|preceding::xhtml:h6)]">
      <xsl:copy>
	<xsl:copy-of select="@*"/>
	<xsl:call-template name="first-slide"/>
      </xsl:copy>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="xhtml:body">
    <xsl:copy>
      <div class="layout">
	<div id="header"></div>
	<div id="footer">
	  <h1><xsl:value-of select="$presdate"/></h1>
	  <h2><xsl:value-of select="$title"/></h2>
	</div>
      </div>
      <div class="presentation">
	<div class="slide">
	  <h1><xsl:value-of select="$title"/></h1>
	  <xsl:if test="$author!=''"><h2><xsl:value-of select="$author"/></h2></xsl:if>
	  <xsl:call-template name="first-slide"/>
	</div>
	<xsl:call-template name="slides"/>
      </div>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>

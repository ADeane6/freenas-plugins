# $FreeBSD$

PORTNAME=	htpc-manager
PORTVERSION=	9.3.0
CATEGORIES=	multimedia

MAINTAINER=	joshruehlig@gmail.com
COMMENT=	Htpc Manager combines all your favorite software into one slick interface.

LICENSE=	MIT PSFL
LICENSE_COMB=	multi

RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}sqlite3>0:${PORTSDIR}/databases/py-sqlite3 \
		${PYTHON_PKGNAMEPREFIX}psutil>0:${PORTSDIR}/sysutils/py-psutil

USES=	python:2.7

USE_GITHUB=     yes
GH_ACCOUNT=     styxit  
GH_PROJECT=     HTPC-Manager
GH_COMMIT=      e6de7ab
GH_TAGNAME=     ${GH_COMMIT}

NO_BUILD=	yes
PLIST_SUB=	PORTNAME=${PORTNAME} USER=${USERS} GROUP=${GROUPS}
SUB_LIST=	PORTNAME=${PORTNAME} USER=${USERS} GROUP=${GROUPS} PYTHON_CMD=${PYTHON_CMD}
SUB_FILES=	pkg-message
USE_RC_SUBR=	${PORTNAME}

USERS=		media
GROUPS=		${USERS}

OPTIONS_DEFINE=	OPENSSL PIL
OPTIONS_DEFAULT=	OPENSSL PIL
PIL_DESC=	convert and resize images retrieved from the XBMC API

.include <bsd.port.pre.mk>

.if ${PORT_OPTIONS:MOPENSSL}
RUN_DEPENDS+=	${PYTHON_PKGNAMEPREFIX}openssl>0:${PORTSDIR}/security/py-openssl
.endif

.if ${PORT_OPTIONS:MPIL}
RUN_DEPENDS+=   ${PYTHON_PKGNAMEPREFIX}imaging>0:${PORTSDIR}/graphics/py-imaging
.endif

do-install:
	${INSTALL} -d ${STAGEDIR}${DATADIR}/${GH_PROJECT}
	cd ${WRKSRC} && ${COPYTREE_SHARE} . ${STAGEDIR}${DATADIR}/${GH_PROJECT}

.include <bsd.port.post.mk>

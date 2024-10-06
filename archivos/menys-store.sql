-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 06-10-2024 a las 01:38:04
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.1.25

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `menys-store`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ActualizarDetalleVenta` (IN `p_codigo_producto` VARCHAR(20), IN `p_cantidad` FLOAT, IN `p_id` INT)   BEGIN

 declare v_nro_boleta varchar(20);
 declare v_total_venta float;

/*
ACTUALIZAR EL STOCK DEL PRODUCTO QUE SEA MODIFICADO
......
.....
.......
*/

/*
ACTULIZAR CODIGO, CANTIDAD Y TOTAL DEL ITEM MODIFICADO
*/

 UPDATE venta_detalle 
 SET codigo_producto = p_codigo_producto, 
 cantidad = p_cantidad, 
 total_venta = (p_cantidad * (select precio_venta_producto from productos where codigo_producto = p_codigo_producto))
 WHERE id = p_id;
 
 set v_nro_boleta = (select nro_boleta from venta_detalle where id = p_id);
 set v_total_venta = (select sum(total_venta) from venta_detalle where nro_boleta = v_nro_boleta);
 
 update venta_cabecera
   set total_venta = v_total_venta
 where nro_boleta = v_nro_boleta;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_eliminar_venta` (IN `p_nro_boleta` VARCHAR(8))   BEGIN

DECLARE v_codigo VARCHAR(20);
DECLARE v_cantidad FLOAT;
DECLARE done INT DEFAULT FALSE;

DECLARE cursor_i CURSOR FOR 
SELECT codigo_producto,cantidad 
FROM venta_detalle 
where CAST(nro_boleta AS CHAR CHARACTER SET utf8)  = CAST(p_nro_boleta AS CHAR CHARACTER SET utf8) ;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

OPEN cursor_i;
read_loop: LOOP
FETCH cursor_i INTO v_codigo, v_cantidad;

	IF done THEN
	  LEAVE read_loop;
	END IF;
    
    UPDATE PRODUCTOS 
       SET stock_producto = stock_producto + v_cantidad
    WHERE CAST(codigo_producto AS CHAR CHARACTER SET utf8) = CAST(v_codigo AS CHAR CHARACTER SET utf8);
    
END LOOP;
CLOSE cursor_i;

DELETE FROM VENTA_DETALLE WHERE CAST(nro_boleta AS CHAR CHARACTER SET utf8) = CAST(p_nro_boleta AS CHAR CHARACTER SET utf8) ;
DELETE FROM VENTA_CABECERA WHERE CAST(nro_boleta AS CHAR CHARACTER SET utf8)  = CAST(p_nro_boleta AS CHAR CHARACTER SET utf8) ;

SELECT 'Se eliminó correctamente la venta';
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarCategorias` ()   BEGIN
select * from categorias;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarClientes` ()   BEGIN
select * from clientes;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductos` ()   SELECT   '' as detalles,
		codigo_producto,
		id_categoria_producto,
		nombre_categoria,
		descripcion_producto,
		ROUND(precio_compra_producto,2) as precio_compra_producto,
		ROUND(precio_venta_producto,2) as precio_venta_producto,
        ROUND(precio_mayor_producto,2) as precio_mayor_producto,
        ROUND(precio_oferta_producto,2) as precio_oferta_producto,
		case when c.aplica_peso = 1 then concat(stock_producto,' Kg(s)')
			else concat(stock_producto,' Und(s)') end as stock_producto,
		case when c.aplica_peso = 1 then concat(minimo_stock_producto,' Kg(s)')
			else concat(minimo_stock_producto,' Und(s)') end as minimo_stock_producto,
		case when c.aplica_peso = 1 then concat(ventas_producto,' Kg(s)') 
			else concat(ventas_producto,' Und(s)') end as ventas_producto,
		ROUND(costo_total_producto,2) as costo_total_producto,
		fecha_creacion_producto,
		fecha_actualizacion_producto,
		'' as acciones
	FROM productos p INNER JOIN categorias c on p.id_categoria_producto = c.id_categoria 
	order by p.codigo_producto desc$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductosMasVendidos` ()  NO SQL BEGIN

select  p.codigo_producto,
		p.descripcion_producto,
        sum(vd.cantidad) as cantidad,
        sum(Round(vd.total_venta,2)) as total_venta
from venta_detalle vd inner join productos p on vd.codigo_producto = p.codigo_producto
group by p.codigo_producto,
		p.descripcion_producto
order by  sum(Round(vd.total_venta,2)) DESC
limit 10;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductosPocoStock` ()  NO SQL BEGIN
select p.codigo_producto,
		p.descripcion_producto,
        p.stock_producto,
        p.minimo_stock_producto
from productos p
where p.stock_producto <= p.minimo_stock_producto
order by p.stock_producto asc;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerDatosDashboard` ()  NO SQL BEGIN
  DECLARE totalProductos int;
  DECLARE totalCompras float;
  DECLARE totalVentas float;
  DECLARE ganancias float;
  DECLARE productosPocoStock int;
  DECLARE ventasHoy float;

  SET totalProductos = (SELECT
      COUNT(*)
    FROM productos p);
  SET totalCompras = (SELECT
      SUM(p.costo_total_producto)
    FROM productos p);
  /*set totalVentas = (select sum(vc.total_venta) from venta_cabecera vc where EXTRACT(MONTH FROM vc.fecha_venta) = EXTRACT(MONTH FROM curdate()) and EXTRACT(YEAR FROM vc.fecha_venta) = EXTRACT(YEAR FROM curdate()));*/
  SET totalVentas = (SELECT
      SUM(vc.total_venta)
    FROM venta_cabecera vc);
  /*set ganancias = (select sum(vd.total_venta - (p.precio_compra_producto * vd.cantidad)) 
  					from venta_detalle vd inner join productos p on vd.codigo_producto = p.codigo_producto
                   where EXTRACT(MONTH FROM vd.fecha_venta) = EXTRACT(MONTH FROM curdate()) 
                   and EXTRACT(YEAR FROM vd.fecha_venta) = EXTRACT(YEAR FROM curdate()));*/
  SET ganancias = (SELECT
      SUM(vd.cantidad * vd.precio_unitario_venta) - SUM(vd.cantidad * vd.costo_unitario_venta)
    FROM venta_detalle VD);
  SET productosPocoStock = (SELECT
      COUNT(1)
    FROM productos p
    WHERE p.stock_producto <= p.minimo_stock_producto);
  SET ventasHoy = (SELECT
      SUM(vc.total_venta)
    FROM venta_cabecera vc
    WHERE DATE(vc.fecha_venta) = CURDATE());

  SELECT
    IFNULL(totalProductos, 0) AS totalProductos,
    IFNULL(CONCAT('Q. ', FORMAT(totalCompras, 2)), 0) AS totalCompras,
    IFNULL(CONCAT('Q. ', FORMAT(totalVentas, 2)), 0) AS totalVentas,
    IFNULL(CONCAT('Q. ', FORMAT(ganancias, 2)), 0) AS ganancias,
    IFNULL(productosPocoStock, 0) AS productosPocoStock,
    IFNULL(CONCAT('Q. ', FORMAT(ventasHoy, 2)), 0) AS ventasHoy;



END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_obtenerNroBoleta` ()  NO SQL select serie_boleta,
		IFNULL(LPAD(max(c.nro_correlativo_venta)+1,8,'0'),'00000001') nro_venta 
from empresa c$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerVentasMesActual` ()  NO SQL BEGIN
SELECT date(vc.fecha_venta) as fecha_venta,
		sum(round(vc.total_venta,2)) as total_venta,
        (SELECT sum(round(vc1.total_venta,2))
			FROM venta_cabecera vc1
		where date(vc1.fecha_venta) >= date(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
		and date(vc1.fecha_venta) <= last_day(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
        and date(vc1.fecha_venta) = DATE_ADD(vc.fecha_venta, INTERVAL -1 MONTH)
		group by date(vc1.fecha_venta)) as total_venta_ant
FROM venta_cabecera vc
where date(vc.fecha_venta) >= date(last_day(now() - INTERVAL 1 month) + INTERVAL 1 day)
and date(vc.fecha_venta) <= last_day(date(CURRENT_DATE))
group by date(vc.fecha_venta);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerVentasMesAnterior` ()  NO SQL BEGIN
SELECT date(vc.fecha_venta) as fecha_venta,
		sum(round(vc.total_venta,2)) as total_venta,
        sum(round(vc.total_venta,2)) as total_venta_ant
FROM venta_cabecera vc
where date(vc.fecha_venta) >= date(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
and date(vc.fecha_venta) <= last_day(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
group by date(vc.fecha_venta);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_bono` (IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_nuevo_stock` FLOAT)   BEGIN

	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_in float;
	declare v_costo_unitario_in float;    
	declare v_costo_total_in float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/
    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM KARDEX K
    WHERE K.CODIGO_PRODUCTO = p_codigo_producto
    ORDER BY ID DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE INGRESO*/
    SET v_unidades_in = p_nuevo_stock;
    SET v_costo_unitario_in = 0;
    SET v_costo_total_in = v_unidades_in * v_costo_unitario_in;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(v_unidades_in,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex + v_costo_total_in,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
        
	INSERT INTO KARDEX(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        in_unidades,
                        in_costo_unitario,
                        in_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        '',
                        v_unidades_in,
                        v_costo_unitario_in,
                        v_costo_total_in,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE PRODUCTOS 
	SET stock_producto = v_unidades_ex, 
        precio_compra_producto = v_costo_unitario_ex,
        costo_total_producto = v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_existencias` (IN `p_codigo_producto` VARCHAR(25), IN `p_concepto` VARCHAR(100), IN `p_comprobante` VARCHAR(100), IN `p_unidades` FLOAT, IN `p_costo_unitario` FLOAT, IN `p_costo_total` FLOAT)   BEGIN
  INSERT INTO KARDEX (codigo_producto, fecha, concepto, comprobante, ex_unidades, ex_costo_unitario, ex_costo_total)
    VALUES (p_codigo_producto, CURDATE(), p_concepto, p_comprobante, p_unidades, p_costo_unitario, p_costo_total);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_vencido` (IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_nuevo_stock` FLOAT)   BEGIN

	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_out float;
	declare v_costo_unitario_out float;    
	declare v_costo_total_out float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM KARDEX K
    WHERE K.CODIGO_PRODUCTO = p_codigo_producto
    ORDER BY ID DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE SALIDA*/
    SET v_unidades_out = p_nuevo_stock;
    SET v_costo_unitario_out = 0;
    SET v_costo_total_out = v_unidades_out * v_costo_unitario_out;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(v_unidades_out,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex - v_costo_total_out,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
        
	INSERT INTO KARDEX(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        out_unidades,
                        out_costo_unitario,
                        out_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        '',
                        v_unidades_out,
                        v_costo_unitario_out,
                        v_costo_total_out,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE PRODUCTOS 
	SET stock_producto = v_unidades_ex, 
        precio_compra_producto = v_costo_unitario_ex,
        costo_total_producto = v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_venta` (IN `p_codigo_producto` VARCHAR(20), IN `p_fecha` DATE, IN `p_concepto` VARCHAR(100), IN `p_comprobante` VARCHAR(100), IN `p_unidades` FLOAT)   BEGIN

	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_out float;
	declare v_costo_unitario_out float;    
	declare v_costo_total_out float;
    

	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/
    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM KARDEX K
    WHERE K.CODIGO_PRODUCTO = p_codigo_producto
    ORDER BY ID DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE SALIDA*/
    SET v_unidades_out = p_unidades;
    SET v_costo_unitario_out = v_costo_unitario_ex;
    SET v_costo_total_out = p_unidades * v_costo_unitario_ex;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(v_unidades_ex - v_unidades_out,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex -  v_costo_total_out,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
        
	INSERT INTO KARDEX(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        out_unidades,
                        out_costo_unitario,
                        out_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						p_fecha,
                        p_concepto,
                        p_comprobante,
                        v_unidades_out,
                        v_costo_unitario_out,
                        v_costo_total_out,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE PRODUCTOS 
	SET stock_producto = v_unidades_ex, 
		ventas_producto = ventas_producto + v_unidades_out,
        precio_compra_producto = v_costo_unitario_ex,
        costo_total_producto = v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_venta_detalle` (IN `p_nro_boleta` VARCHAR(8), IN `p_codigo_producto` VARCHAR(20), IN `p_cantidad` FLOAT, IN `p_total_venta` FLOAT)   BEGIN
declare v_precio_compra float;
declare v_precio_venta float;

SELECT p.precio_compra_producto,p.precio_venta_producto
into v_precio_compra, v_precio_venta
FROM productos p
WHERE p.codigo_producto  = p_codigo_producto;
    
INSERT INTO venta_detalle(nro_boleta,codigo_producto, cantidad, costo_unitario_venta,precio_unitario_venta,total_venta, fecha_venta) 
VALUES(p_nro_boleta,p_codigo_producto,p_cantidad, v_precio_compra, v_precio_venta,p_total_venta,curdate());
                                                        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_top_ventas_categorias` ()   BEGIN

select cast(sum(vd.total_venta)  AS DECIMAL(8,2)) as y, c.nombre_categoria as label
    from venta_detalle vd inner join productos p on vd.codigo_producto = p.codigo_producto
                        inner join categorias c on c.id_categoria = p.id_categoria_producto
    group by c.nombre_categoria
    LIMIT 10;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `arqueo_caja`
--

CREATE TABLE `arqueo_caja` (
  `id` int(11) NOT NULL,
  `id_caja` int(11) DEFAULT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `fecha_inicio` datetime DEFAULT NULL,
  `fecha_fin` datetime DEFAULT NULL,
  `monto_inicial` float DEFAULT NULL,
  `ingresos` float DEFAULT NULL,
  `devoluciones` float DEFAULT NULL,
  `gastos` float DEFAULT NULL,
  `monto_final` float DEFAULT NULL,
  `status` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cajas`
--

CREATE TABLE `cajas` (
  `id` int(11) NOT NULL,
  `numero_caja` int(11) NOT NULL,
  `nombre_caja` varchar(100) NOT NULL,
  `estado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `id_categoria` int(11) NOT NULL,
  `nombre_categoria` text DEFAULT NULL,
  `aplica_peso` int(11) NOT NULL,
  `fecha_creacion_categoria` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `fecha_actualizacion_categoria` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`id_categoria`, `nombre_categoria`, `aplica_peso`, `fecha_creacion_categoria`, `fecha_actualizacion_categoria`) VALUES
(3622, 'Abrigos', 0, '2024-10-04 03:23:56', '2024-10-04'),
(3623, 'Faldas', 0, '2024-10-04 03:59:29', '2024-10-04'),
(3624, 'Playeras', 0, '2024-10-05 05:01:33', '2024-10-05');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id` int(11) NOT NULL,
  `nombres` varchar(50) NOT NULL,
  `apellidos` varchar(50) NOT NULL,
  `telefono` int(8) NOT NULL,
  `direccion` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`id`, `nombres`, `apellidos`, `telefono`, `direccion`) VALUES
(2, 'Deysy Elizabeth', 'Morales Tol', 11235648, 'Chichicastenango'),
(3, 'Maria Lucia', 'Perez Solano', 11125458, 'Guatemala');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compras`
--

CREATE TABLE `compras` (
  `id` int(11) NOT NULL,
  `id_proveedor` int(11) DEFAULT NULL,
  `id_tipo_comprobante` varchar(3) DEFAULT NULL,
  `serie_comprobante` varchar(10) DEFAULT NULL,
  `nro_comprobante` varchar(20) DEFAULT NULL,
  `fecha_comprobante` datetime DEFAULT NULL,
  `id_moneda_comprobante` int(11) DEFAULT NULL,
  `ope_exonerada` float DEFAULT NULL,
  `ope_inafecta` float DEFAULT NULL,
  `ope_gravada` float DEFAULT NULL,
  `igv` float DEFAULT NULL,
  `total_compra` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_compra`
--

CREATE TABLE `detalle_compra` (
  `id` int(11) NOT NULL,
  `id_compra` int(11) DEFAULT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `cantidad` float DEFAULT NULL,
  `costo_unitario` float DEFAULT NULL,
  `descuento` float DEFAULT NULL,
  `subtotal` float DEFAULT NULL,
  `impuesto` float DEFAULT NULL,
  `total` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empresa`
--

CREATE TABLE `empresa` (
  `id_empresa` int(11) NOT NULL,
  `razon_social` text NOT NULL,
  `ruc` bigint(20) NOT NULL,
  `direccion` text NOT NULL,
  `marca` text NOT NULL,
  `serie_boleta` varchar(4) NOT NULL,
  `nro_correlativo_venta` varchar(8) NOT NULL,
  `email` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `empresa`
--

INSERT INTO `empresa` (`id_empresa`, `razon_social`, `ruc`, `direccion`, `marca`, `serie_boleta`, `nro_correlativo_venta`, `email`) VALUES
(1, 'Maga & Tito Market', 10467291241, 'Avenida Brasil 1347 - Jesus María', 'Maga & Tito Market', 'B001', '00000256', 'magaytito@gmail.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `kardex`
--

CREATE TABLE `kardex` (
  `id` int(11) NOT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `fecha` datetime DEFAULT NULL,
  `concepto` varchar(100) DEFAULT NULL,
  `comprobante` varchar(50) DEFAULT NULL,
  `in_unidades` float DEFAULT NULL,
  `in_costo_unitario` float DEFAULT NULL,
  `in_costo_total` float DEFAULT NULL,
  `out_unidades` float DEFAULT NULL,
  `out_costo_unitario` float DEFAULT NULL,
  `out_costo_total` float DEFAULT NULL,
  `ex_unidades` float DEFAULT NULL,
  `ex_costo_unitario` float DEFAULT NULL,
  `ex_costo_total` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `kardex`
--

INSERT INTO `kardex` (`id`, `codigo_producto`, `fecha`, `concepto`, `comprobante`, `in_unidades`, `in_costo_unitario`, `in_costo_total`, `out_unidades`, `out_costo_unitario`, `out_costo_total`, `ex_unidades`, `ex_costo_unitario`, `ex_costo_total`) VALUES
(5667, '5745625986566', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 2, 550, 141.6),
(5668, '7755139002903', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 3, 100, 278.3),
(5669, '7755139002904', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 3, 100, 359.6),
(5670, '7755139002870', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 3.25, 84.5),
(5671, '7755139002880', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 5.15, 118.45),
(5672, '7755139002902', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 9.8, 284.2),
(5673, '7755139002898', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 7.49, 202.23),
(5674, '7755139002899', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 8, 208),
(5675, '7755139002901', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 10, 260),
(5676, '7755139002810', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 3.79, 79.59),
(5677, '7755139002878', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 3.99, 99.75),
(5678, '7755139002838', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 1.29, 34.83),
(5679, '7755139002839', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 1, 27),
(5680, '7755139002848', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 1.9, 47.5),
(5681, '7755139002863', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 2.8, 75.6),
(5682, '7755139002864', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 4.4, 88),
(5683, '7755139002865', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 3.79, 87.17),
(5684, '7755139002866', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 3.79, 98.54),
(5685, '7755139002867', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 3.65, 87.6),
(5686, '7755139002868', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 3.5, 70),
(5687, '7755139002871', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 3.17, 85.59),
(5688, '7755139002877', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 30, 5.17, 155.1),
(5689, '7755139002879', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 4.58, 128.24),
(5690, '7755139002881', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 5, 110),
(5691, '7755139002882', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 4.66, 125.82),
(5692, '7755139002883', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 4.65, 106.95),
(5693, '7755139002884', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 4.63, 97.23),
(5694, '7755139002885', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 5.7, 153.9),
(5695, '7755139002887', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 6.08, 164.16),
(5696, '7755139002888', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 5.9, 129.8),
(5697, '7755139002889', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 5.9, 165.2),
(5698, '7755139002891', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 5.9, 171.1),
(5699, '7755139002892', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 5.08, 106.68),
(5700, '7755139002893', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 5.63, 163.27),
(5701, '7755139002895', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 5.9, 171.1),
(5702, '7755139002896', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 5.9, 159.3),
(5703, '7755139002897', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 5.33, 117.26),
(5704, '7755139002900', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 8.9, 186.9),
(5705, '7755139002886', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 5.7, 119.7),
(5706, '7755139002809', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 18.29, 384.09),
(5707, '7755139002874', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 2.8, 78.4),
(5708, '7755139002830', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 1, 20),
(5709, '7755139002869', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 3.25, 68.25),
(5710, '7755139002872', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 30, 3.1, 93),
(5711, '7755139002876', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 3.39, 71.19),
(5712, '7755139002852', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 1.3, 26),
(5713, '7755139002853', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 1.99, 55.72),
(5714, '7755139002840', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 1, 29),
(5715, '7755139002894', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 5.4, 124.2),
(5716, '7755139002814', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 0.53, 13.25),
(5717, '7755139002831', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 0.9, 20.7),
(5718, '7755139002832', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 0.9, 22.5),
(5719, '7755139002835', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 30, 0.67, 20.1),
(5720, '7755139002846', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 1.39, 30.58),
(5721, '7755139002847', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 30, 1.39, 41.7),
(5722, '7755139002850', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 1.39, 29.19),
(5723, '7755139002851', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 1.39, 34.75),
(5724, '7755139002854', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 2.8, 58.8),
(5725, '7755139002855', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 2.6, 57.2),
(5726, '7755139002856', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 2.6, 62.4),
(5727, '7755139002857', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 2.19, 52.56),
(5728, '7755139002861', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 2.19, 61.32),
(5729, '7755139002811', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 3.4, 85),
(5730, '7755139002812', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 0.5, 14),
(5731, '7755139002833', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 0.88, 21.12),
(5732, '7755139002837', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 1.5, 36),
(5733, '7755139002815', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 0.37, 10.73),
(5734, '7755139002817', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 0.68, 14.28),
(5735, '7755139002822', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 0.52, 12.48),
(5736, '7755139002823', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 0.52, 10.4),
(5737, '7755139002824', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 0.52, 11.96),
(5738, '7755139002826', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 0.47, 12.69),
(5739, '7755139002827', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 0.47, 11.28),
(5740, '7755139002828', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 0.47, 13.63),
(5741, '7755139002842', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 0.9, 26.1),
(5742, '7755139002818', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 0.62, 14.88),
(5743, '7755139002836', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 0.56, 12.32),
(5744, '7755139002825', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 0.5, 12.5),
(5745, '7755139002849', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 1.8, 50.4),
(5746, '7755139002875', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 3.69, 81.18),
(5747, '7755139002860', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 2.8, 75.6),
(5748, '7755139002813', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 0.33, 7.26),
(5749, '7755139002816', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 0.43, 8.6),
(5750, '7755139002829', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 0.75, 21.75),
(5751, '7755139002819', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 0.6, 16.8),
(5752, '7755139002834', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 0.85, 17.85),
(5753, '7755139002841', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 0.92, 23.92),
(5754, '7755139002843', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 1.06, 24.38),
(5755, '7755139002844', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 1.5, 39),
(5756, '7755139002845', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 1.5, 31.5),
(5757, '7755139002858', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 2.6, 59.8),
(5758, '7755139002859', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 3, 63),
(5759, '7755139002862', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 3.2, 83.2),
(5760, '7755139002873', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 2.89, 72.25),
(5761, '7755139002820', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 0.57, 11.97),
(5762, '7755139002821', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 0.53, 11.66),
(5763, '234567898765', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 5, 500, 2500),
(5764, '2345678907654', '2024-10-03 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 6, 100, 600),
(5765, '2345678907654', '2024-10-04 00:00:00', 'VENTA', '00000255', NULL, NULL, NULL, 2, 100, 200, 4, 100, 400),
(5766, '2345678907654', '2024-10-03 00:00:00', 'VENCIMIENTO', '', NULL, NULL, NULL, 2, 0, 0, 2, 200, 400),
(5767, '234567898765', '2024-10-05 00:00:00', 'VENTA', '00000256', NULL, NULL, NULL, 1, 500, 500, 4, 500, 2000);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modulos`
--

CREATE TABLE `modulos` (
  `id` int(11) NOT NULL,
  `modulo` varchar(45) DEFAULT NULL,
  `padre_id` int(11) DEFAULT NULL,
  `vista` varchar(45) DEFAULT NULL,
  `icon_menu` varchar(45) DEFAULT NULL,
  `orden` int(11) DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT NULL,
  `fecha_actualizacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `modulos`
--

INSERT INTO `modulos` (`id`, `modulo`, `padre_id`, `vista`, `icon_menu`, `orden`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(1, 'Tablero Principal', 0, 'dashboard.php', 'fas fa-tachometer-alt', 0, NULL, NULL),
(2, 'Ventas', 0, '', 'fas fa-store-alt', 1, NULL, NULL),
(3, 'Punto de Venta', 2, 'ventas.php', 'far fa-circle', 2, NULL, NULL),
(4, 'Administrar Ventas', 2, 'administrar_ventas.php', 'far fa-circle', 3, NULL, NULL),
(5, 'Productos', 0, NULL, 'fas fa-cart-plus', 4, NULL, NULL),
(6, 'Inventario', 5, 'productos.php', 'far fa-circle', 5, NULL, NULL),
(7, 'Carga Masiva', 5, 'carga_masiva_productos.php', 'far fa-circle', 6, NULL, NULL),
(8, 'Categorías', 5, 'categorias.php', 'far fa-circle', 7, NULL, NULL),
(9, 'Compras', 0, 'compras.php', 'fas fa-dolly', 9, NULL, NULL),
(10, 'Reportes', 0, 'reportes.php', 'fas fa-chart-line', 10, NULL, NULL),
(11, 'Configuración', 0, 'configuracion.php', 'fas fa-cogs', 11, NULL, NULL),
(12, 'Usuarios', 0, 'usuarios.php', 'fas fa-users', 12, NULL, NULL),
(13, 'Roles y Perfiles', 0, 'modulos_perfiles.php', 'fas fa-tablet-alt', 13, NULL, NULL),
(15, 'Caja', 0, 'caja.php', 'fas fa-cash-register', 8, '2022-12-05 09:44:08', NULL),
(16, 'Clientes', 0, 'clientes.php', 'fas fa-users', 14, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `monedas`
--

CREATE TABLE `monedas` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfiles`
--

CREATE TABLE `perfiles` (
  `id_perfil` int(11) NOT NULL,
  `descripcion` varchar(45) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT NULL,
  `fecha_actualizacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `perfiles`
--

INSERT INTO `perfiles` (`id_perfil`, `descripcion`, `estado`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(1, 'Administrador', 1, NULL, NULL),
(2, 'Vendedor', 1, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfil_modulo`
--

CREATE TABLE `perfil_modulo` (
  `idperfil_modulo` int(11) NOT NULL,
  `id_perfil` int(11) DEFAULT NULL,
  `id_modulo` int(11) DEFAULT NULL,
  `vista_inicio` tinyint(4) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `perfil_modulo`
--

INSERT INTO `perfil_modulo` (`idperfil_modulo`, `id_perfil`, `id_modulo`, `vista_inicio`, `estado`) VALUES
(13, 1, 13, NULL, 1),
(173, 2, 1, 1, 1),
(174, 2, 3, 0, 1),
(175, 2, 2, 0, 1),
(176, 2, 15, 0, 1),
(177, 2, 5, 0, 1),
(178, 2, 6, 0, 1),
(179, 2, 7, 0, 1),
(180, 2, 8, 0, 1),
(181, 1, 1, 1, 1),
(182, 1, 3, 0, 1),
(183, 1, 2, 0, 1),
(184, 1, 4, 0, 1),
(185, 1, 6, 0, 1),
(186, 1, 5, 0, 1),
(187, 1, 7, 0, 1),
(188, 1, 8, 0, 1),
(189, 1, 15, 0, 1),
(190, 1, 16, 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `codigo_producto` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `id_categoria_producto` int(11) DEFAULT NULL,
  `imagen_producto` varchar(70) NOT NULL,
  `descripcion_producto` text CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `precio_compra_producto` float NOT NULL,
  `precio_venta_producto` float NOT NULL,
  `precio_mayor_producto` float DEFAULT NULL,
  `precio_oferta_producto` float DEFAULT NULL,
  `stock_producto` float DEFAULT NULL,
  `minimo_stock_producto` float DEFAULT NULL,
  `ventas_producto` float DEFAULT NULL,
  `costo_total_producto` float DEFAULT NULL,
  `fecha_creacion_producto` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `fecha_actualizacion_producto` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`codigo_producto`, `id_categoria_producto`, `imagen_producto`, `descripcion_producto`, `precio_compra_producto`, `precio_venta_producto`, `precio_mayor_producto`, `precio_oferta_producto`, `stock_producto`, `minimo_stock_producto`, `ventas_producto`, `costo_total_producto`, `fecha_creacion_producto`, `fecha_actualizacion_producto`) VALUES
('2345678907654', 3624, '66ff6ab084be8_486.jpg', 'Playera colo rojo talla S', 200, 150, 120, 125, 2, 2, NULL, 400, '2024-10-04 04:28:34', '2024-10-04'),
('234567898765', 3622, '66ff689f53bcd_161.jpg', 'Abrigo colo azul pavo', 500, 650, 600, 625, 4, 1, NULL, 2000, '2024-10-05 05:27:56', '2024-10-04');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `id` int(11) NOT NULL,
  `ruc` varchar(45) DEFAULT NULL,
  `razon_social` varchar(100) DEFAULT NULL,
  `direccion` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_comprobante`
--

CREATE TABLE `tipo_comprobante` (
  `id` varchar(3) NOT NULL,
  `descripcion` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `nombre_usuario` varchar(100) DEFAULT NULL,
  `apellido_usuario` varchar(100) DEFAULT NULL,
  `usuario` varchar(100) DEFAULT NULL,
  `clave` text DEFAULT NULL,
  `id_perfil_usuario` int(11) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `nombre_usuario`, `apellido_usuario`, `usuario`, `clave`, `id_perfil_usuario`, `estado`) VALUES
(1, 'Deysy', 'Morales', 'dmorales', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 1, 1),
(2, 'Karina', 'Mejia', 'kmejia', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 2, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta_cabecera`
--

CREATE TABLE `venta_cabecera` (
  `nro_boleta` varchar(8) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `descripcion` text CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `subtotal` float NOT NULL,
  `igv` float NOT NULL,
  `total_venta` float DEFAULT NULL,
  `fecha_venta` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `venta_cabecera`
--

INSERT INTO `venta_cabecera` (`nro_boleta`, `descripcion`, `subtotal`, `igv`, `total_venta`, `fecha_venta`) VALUES
('00000255', 'Venta realizada con Nro Boleta: 00000255', 0, 0, 300, '2024-10-04 04:11:43'),
('00000256', 'Venta realizada con Nro Boleta: 00000256', 0, 0, 650, '2024-10-05 05:27:56');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta_detalle`
--

CREATE TABLE `venta_detalle` (
  `id` int(11) NOT NULL,
  `nro_boleta` varchar(8) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `codigo_producto` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `cantidad` float NOT NULL,
  `costo_unitario_venta` float DEFAULT NULL,
  `precio_unitario_venta` float DEFAULT NULL,
  `total_venta` float NOT NULL,
  `fecha_venta` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `venta_detalle`
--

INSERT INTO `venta_detalle` (`id`, `nro_boleta`, `codigo_producto`, `cantidad`, `costo_unitario_venta`, `precio_unitario_venta`, `total_venta`, `fecha_venta`) VALUES
(145, '00000255', '2345678907654', 2, 100, 150, 300, '2024-10-03'),
(146, '00000256', '234567898765', 1, 500, 650, 0, '2024-10-04');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `arqueo_caja`
--
ALTER TABLE `arqueo_caja`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_id_caja_idx` (`id_caja`),
  ADD KEY `fk_id_usuario_idx` (`id_usuario`);

--
-- Indices de la tabla `cajas`
--
ALTER TABLE `cajas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id_categoria`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_id_proveedor_idx` (`id_proveedor`),
  ADD KEY `fk_id_comprobante_idx` (`id_tipo_comprobante`),
  ADD KEY `fk_id_moneda_idx` (`id_moneda_comprobante`);

--
-- Indices de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_cod_producto_idx` (`codigo_producto`),
  ADD KEY `fk_id_compra_idx` (`id_compra`);

--
-- Indices de la tabla `empresa`
--
ALTER TABLE `empresa`
  ADD PRIMARY KEY (`id_empresa`);

--
-- Indices de la tabla `kardex`
--
ALTER TABLE `kardex`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_id_producto_idx` (`codigo_producto`);

--
-- Indices de la tabla `modulos`
--
ALTER TABLE `modulos`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `monedas`
--
ALTER TABLE `monedas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `perfiles`
--
ALTER TABLE `perfiles`
  ADD PRIMARY KEY (`id_perfil`);

--
-- Indices de la tabla `perfil_modulo`
--
ALTER TABLE `perfil_modulo`
  ADD PRIMARY KEY (`idperfil_modulo`),
  ADD KEY `id_perfil` (`id_perfil`),
  ADD KEY `id_modulo` (`id_modulo`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`codigo_producto`),
  ADD UNIQUE KEY `codigo_producto_UNIQUE` (`codigo_producto`),
  ADD KEY `fk_id_categoria_idx` (`id_categoria_producto`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tipo_comprobante`
--
ALTER TABLE `tipo_comprobante`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD KEY `id_perfil_usuario` (`id_perfil_usuario`);

--
-- Indices de la tabla `venta_cabecera`
--
ALTER TABLE `venta_cabecera`
  ADD PRIMARY KEY (`nro_boleta`);

--
-- Indices de la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_nro_boleta_idx` (`nro_boleta`),
  ADD KEY `fk_cod_producto_idx` (`codigo_producto`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `arqueo_caja`
--
ALTER TABLE `arqueo_caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cajas`
--
ALTER TABLE `cajas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id_categoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3625;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `compras`
--
ALTER TABLE `compras`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `empresa`
--
ALTER TABLE `empresa`
  MODIFY `id_empresa` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `kardex`
--
ALTER TABLE `kardex`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5768;

--
-- AUTO_INCREMENT de la tabla `modulos`
--
ALTER TABLE `modulos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT de la tabla `monedas`
--
ALTER TABLE `monedas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `perfiles`
--
ALTER TABLE `perfiles`
  MODIFY `id_perfil` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `perfil_modulo`
--
ALTER TABLE `perfil_modulo`
  MODIFY `idperfil_modulo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=191;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=147;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `arqueo_caja`
--
ALTER TABLE `arqueo_caja`
  ADD CONSTRAINT `fk_id_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_id_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `compras`
--
ALTER TABLE `compras`
  ADD CONSTRAINT `fk_id_comprobante` FOREIGN KEY (`id_tipo_comprobante`) REFERENCES `tipo_comprobante` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_id_moneda` FOREIGN KEY (`id_moneda_comprobante`) REFERENCES `monedas` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_id_proveedor` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD CONSTRAINT `fk_cod_producto` FOREIGN KEY (`codigo_producto`) REFERENCES `productos` (`codigo_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_id_compra` FOREIGN KEY (`id_compra`) REFERENCES `compras` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `kardex`
--
ALTER TABLE `kardex`
  ADD CONSTRAINT `fk_cod_producto_kardex` FOREIGN KEY (`codigo_producto`) REFERENCES `productos` (`codigo_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `perfil_modulo`
--
ALTER TABLE `perfil_modulo`
  ADD CONSTRAINT `id_modulo` FOREIGN KEY (`id_modulo`) REFERENCES `modulos` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `id_perfil` FOREIGN KEY (`id_perfil`) REFERENCES `perfiles` (`id_perfil`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `fk_id_categoria` FOREIGN KEY (`id_categoria_producto`) REFERENCES `categorias` (`id_categoria`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`id_perfil_usuario`) REFERENCES `perfiles` (`id_perfil`);

--
-- Filtros para la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  ADD CONSTRAINT `fk_cod_producto_detalle` FOREIGN KEY (`codigo_producto`) REFERENCES `productos` (`codigo_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_nro_boleta` FOREIGN KEY (`nro_boleta`) REFERENCES `venta_cabecera` (`nro_boleta`) ON DELETE NO ACTION ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

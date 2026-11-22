/* =====================================================================
   PRY2205 - CONSULTA DE BASES DE DATOS
   SEMANA 5 - ACTIVIDAD FORMATIVA 4:
   "UTILIZANDO SUBCONSULTAS PARA RESOLVER REQUERIMIENTOS"
   Caso: Gestion de clientes y productos financieros "FinanCorp"

   Grupo 12: Betina Elena Salinas Rojas - Cristobal Alejandro Robles Escobar
   Usuario BD : PRY2205_S5
   Conexion   : PRY2205_ACTIVIDAD_S5

   PASOS PREVIOS (segun instrucciones especificas de la semana):
     1. Conectado como SYS / SYSTEM (o ADMIN en Oracle Cloud), ejecutar
        script_crea_usuario_PRY2205_S5.sql, que crea el usuario PRY2205_S5.
     2. Crear la conexion PRY2205_ACTIVIDAD_S5 con dicho usuario.
     3. Conectado con PRY2205_S5, ejecutar
        PRY2205_Exp2_S5_CreaEsquemaPoblado.sql, que crea y pobla las tablas.
     4. Ejecutar el presente script.

   CONSIDERACIONES GENERALES:
     - Los valores se trabajan REDONDEADOS a enteros, sin decimales.
     - No se utilizan fechas fijas: el ano actual y el ano anterior se
       obtienen de forma parametrica con SYSDATE y EXTRACT.
     - No se utiliza la clausula WITH.
   ===================================================================== */

-- Formato numerico chileno: el separador de grupo (G) se muestra como punto.
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ',.';


/* =====================================================================
   CASO 1: LISTADO DE CLIENTES
   ---------------------------------------------------------------------
   Identifica a los clientes trabajadores dependientes cuya profesion u
   oficio es CONTADOR o VENDEDOR, considerando solamente a aquellos cuyo
   ano de inscripcion es mayor al promedio redondeado de todos los anos
   de inscripcion de los clientes.

   El promedio redondeado de los anos de inscripcion se obtiene mediante
   una SUBCONSULTA (funcion de grupo AVG + ROUND).

   Ordenado por RUT del cliente en forma ascendente.
   ===================================================================== */

SELECT LTRIM(TO_CHAR(cli.numrun, '99G999G999')) || '-' || cli.dvrun   AS "RUT Cliente",
       INITCAP(cli.pnombre || ' ' || cli.appaterno)                   AS "Nombre Cliente",
       UPPER(pro.nombre_prof_ofic)                                    AS "Profesión Cliente",
       TO_CHAR(cli.fecha_inscripcion, 'DD-MM-YYYY')                   AS "Fecha de Inscripción",
       NVL(cli.direccion, 'SIN DIRECCION REGISTRADA')                 AS "Dirección Cliente"
FROM   cliente           cli
       JOIN profesion_oficio pro ON cli.cod_prof_ofic   = pro.cod_prof_ofic
       JOIN tipo_cliente     tcl ON cli.cod_tipo_cliente = tcl.cod_tipo_cliente
WHERE  UPPER(tcl.nombre_tipo_cliente) = 'TRABAJADORES DEPENDIENTES'
AND    UPPER(pro.nombre_prof_ofic) IN ('CONTADOR', 'VENDEDOR')
AND    EXTRACT(YEAR FROM cli.fecha_inscripcion) >
       (  /* Subconsulta: promedio redondeado de todos los anos de inscripcion */
          SELECT ROUND(AVG(EXTRACT(YEAR FROM sub.fecha_inscripcion)))
          FROM   cliente sub
       )
ORDER  BY cli.numrun ASC;


/* =====================================================================
   CASO 2: AUMENTO DE CREDITO
   ---------------------------------------------------------------------
   Lista el RUT, la edad, el cupo disponible para compras y el tipo de
   cliente, considerando unicamente a aquellos clientes cuyo cupo
   disponible para compras es mayor o igual al maximo cupo disponible
   registrado en el ano anterior al actual.

   El maximo cupo disponible del ano anterior se obtiene mediante una
   SUBCONSULTA (funcion de grupo MAX), y el ano se calcula de forma
   parametrica con EXTRACT y SYSDATE (sin fechas fijas).

   El resultado se almacena en la tabla CLIENTES_CUPOS_COMPRA, creada a
   partir de la consulta, y queda ordenado por edad en forma ascendente.
   ===================================================================== */

-- Ejecutar la siguiente linea solo si la tabla ya existe de una corrida anterior:
-- DROP TABLE clientes_cupos_compra;

CREATE TABLE clientes_cupos_compra AS
SELECT CONCAT(TO_CHAR(cli.numrun), CONCAT('-', UPPER(cli.dvrun)))        AS rut_cliente,
       EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM cli.fecha_nacimiento)
                                                                         AS edad,
       TO_CHAR(NVL(tar.cupo_disp_compra, 0), '$9G999G999')               AS cupo_disponible_compra,
       UPPER(tcl.nombre_tipo_cliente)                                    AS tipo_cliente
FROM   cliente          cli
       JOIN tarjeta_cliente tar ON tar.numrun           = cli.numrun
       JOIN tipo_cliente    tcl ON cli.cod_tipo_cliente = tcl.cod_tipo_cliente
WHERE  NVL(tar.cupo_disp_compra, 0) >=
       (  /* Subconsulta: maximo cupo disponible de compra del ano anterior al actual */
          SELECT MAX(sub.cupo_disp_compra)
          FROM   tarjeta_cliente sub
          WHERE  EXTRACT(YEAR FROM sub.fecha_solic_tarjeta) =
                 EXTRACT(YEAR FROM SYSDATE) - 1
       )
ORDER  BY edad ASC;

-- Despliegue del contenido de la tabla creada.
SELECT * FROM clientes_cupos_compra;

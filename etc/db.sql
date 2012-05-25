-- MySQL DB
-- phpMyAdmin SQL Dump
-- version 3.3.9
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generato il: 30 mag, 2011 at 05:26 
-- Versione MySQL: 5.5.8
-- Versione PHP: 5.3.5

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

-- TODO  ADD User theConsultant2

--
-- Database: `theconsultant2`
--
CREATE DATABASE `theconsultant2` DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
USE `theconsultant2`;

-- --------------------------------------------------------

--
-- Struttura della tabella `config`
--

CREATE TABLE IF NOT EXISTS `config` (
  `property` varchar(80) COLLATE utf8_bin NOT NULL,
  `value` varchar(4096) COLLATE utf8_bin NOT NULL,
  UNIQUE KEY `property` (`property`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Dump dei dati per la tabella `config`
--

INSERT INTO `config` (`property`, `value`) VALUES
('', ''),
('db_version', '1');

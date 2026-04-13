#!/usr/bin/env node
/// <reference types="node" />
import { X509Certificate } from "crypto";
import { mkdir, writeFile, rename } from "fs/promises";
import { Certificate, ContentInfo, SignedData } from "pkijs";
import { getCACertificates, TLSSocket } from "tls";
import { Agent, buildConnector } from "undici";

const { SCEP_PIN, SCEP_URL } = process.env;

declare global {
    interface RequestInit {
        dispatcher?: Agent;
    }
}

const ca = getCACertificates("system");
const connectNormal = buildConnector({ ca });
const connectPinned = buildConnector({ rejectUnauthorized: false });

const agent = new Agent({
    connect(opts, cb) {
        connectNormal(opts, (err, socket) => {
            if (err) {
                connectPinned(opts, (fail, socket) => {
                    let cert: X509Certificate | undefined;
                    if (socket instanceof TLSSocket) {
                        cert = socket.getPeerX509Certificate();
                    }

                    if (fail) {
                        cb(err, null);
                    }
                    else if (cert) {
                        let valid = CompareHash(cert.fingerprint256, SCEP_PIN)
                        const now = new Date();
                        if (valid && cert.validFromDate > now) {
                            valid = false;
                        }

                        if (valid && cert.validToDate < now) {
                            valid = false;
                        }

                        const pin = cert.fingerprint256.replace(/[: ]/g, "").toUpperCase();
                        console.log("Certificate: PIN = %s VALID = %s", pin, valid);
                        if (valid) {
                            cb(null, socket);
                        }
                        else {
                            socket.destroy();
                            cb(err, null);
                        }
                    }
                    else {
                        cb(null, socket);
                    }
                });
            }
            else {
                cb(null, socket);
            }
        });
    }
});

function CompareHash(x?: string, y?: string) {
    if (!x || !y) {
        return false;
    }

    x = x.replace(/[: ]/g, "").toLowerCase();
    y = y.replace(/[: ]/g, "").toLowerCase();
    return x === y;
}

function CreateName(cert: X509Certificate) {
    const parts = [];
    for (const part of cert.subject.split("\n")) {
        parts.push(part.replace(/.*=/, "").trim());
    }

    let prefix = cert.fingerprint256;
    prefix = prefix.replace(/[: ]/g, "").toUpperCase();
    prefix = prefix.slice(0, 8);

    const date = cert.validToDate;
    const when = date.toISOString().replace(/T.*/, "").replace(/-/g, "");
    let result = parts.reverse().join("_");
    result = result.replace(/[^A-Za-z0-9-]+/g, "_");
    result = result.toUpperCase();

    return `${prefix}_${when}_${result}.crt`;
}

function CreatePEM(cert: Certificate | X509Certificate | ArrayBuffer | Buffer | string) {
    let parts = "";
    if (cert instanceof Certificate) {
        parts = cert.toString("base64");
    }
    else if (cert instanceof X509Certificate) {
        parts = cert.raw.toString("base64");
    }
    else if (Buffer.isBuffer(cert)) {
        parts = cert.toString("base64");
    }
    else if (typeof cert === "string") {
        parts = cert;
    }
    else {
        parts = Buffer.from(cert).toString("base64");
    }

    const n = 64;
    const lines = ["-----BEGIN CERTIFICATE-----"];
    for (let i = 0; i < parts.length; i += n) {
        const j = Math.min(i + n, parts.length);
        lines.push(parts.slice(i, j));
    }

    lines.push("-----END CERTIFICATE-----");
    return lines.join("\n");
}

async function GetCA_Certs() {
    const res = await fetch(SCEP_URL + "?operation=GetCACert", {
        method: "GET",
        dispatcher: agent,
    });

    if (!res.ok) {
        return [];
    }

    const ct = res.headers.get("Content-Type");
    const data = await res.arrayBuffer();
    if (ct === "application/x-x509-ca-cert") {
        const cert = new X509Certificate(CreatePEM(data));
        return [cert];
    }

    if (ct === "application/x-x509-ca-ra-cert") {
        const cms = ContentInfo.fromBER(data);   
        if (cms.contentType === ContentInfo.SIGNED_DATA) {
            const certs: X509Certificate[] = [];
            const signedData = new SignedData({ schema: cms.content });
            for (const cert of signedData.certificates || []) {
                if (cert instanceof Certificate) {
                    certs.push(new X509Certificate(CreatePEM(cert)));
                }
            }

            if (certs.length) {
                return certs;
            }
        }
    }

    return [];
}

async function GetCA_FindAnchors() {
    const certs = await GetCA_Certs();    
    return certs.filter(cert => {
        if (!cert.ca) {
            return false;
        }

        if (cert.issuer !== cert.subject) {
            return false;
        }

        if (!cert.verify(cert.publicKey)) {
            return false;
        }

        return true;
    });
}

async function GetCA_SaveAnchors() {
    const dir = "/usr/local/share/ca-certificates";
    const certs = await GetCA_FindAnchors();
    for (const cert of certs) {
        const name = CreateName(cert);
        const fp = cert.fingerprint256.replace(/[: ]/g, "").toUpperCase();
        console.log("Saving CA Certificate:", name, cert.subject, fp);

        const path = `${dir}/${name}`;
        await mkdir(dir, { recursive: true });
        
        const pem = CreatePEM(cert);
        await writeFile(path + ".tmp", pem);
        await rename(path + ".tmp", path);
    }
}

GetCA_SaveAnchors().catch(err => {
    console.error("Error:", err);
});

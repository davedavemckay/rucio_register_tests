#!/usr/bin/env python3
import sys
import os
import zlib
import traceback

def test_local_path(uri):
    print("=== Testing Local Path Translation ===")
    print(f"Original URI: {uri}")
    
    # Extract path component
    if "://" in uri:
        scheme, rest = uri.split("://", 1)
        if "/" in rest:
            host, path = rest.split("/", 1)
            local_path = "/" + path
        else:
            local_path = "/"
    else:
        local_path = uri
        
    print(f"Inferred local path: {local_path}")
    exists = os.path.exists(local_path)
    print(f"Does local path exist? {exists}")
    
    if not exists:
        print("Checking parent directories to see where mount breaks:")
        parts = local_path.split("/")
        current = ""
        for part in parts:
            if not part and current:
                continue
            next_path = current + "/" + part if current else part
            if not next_path:
                next_path = "/"
            if os.path.exists(next_path):
                print(f"  [EXISTS] {next_path}")
                current = next_path
            else:
                print(f"  [MISSING] {next_path}")
                # Try to list contents of the last working directory
                try:
                    if os.path.isdir(current):
                        print(f"  Contents of {current or '/'}: {os.listdir(current or '/')[:10]}")
                except Exception as e:
                    print(f"  Failed to list {current}: {e}")
                break
    return local_path if exists else None

def test_cephfs_xattr(local_path):
    print("\n=== Testing CephFS Extended Attributes ===")
    if not local_path:
        print("Skipping CephFS xattr check (local path does not exist).")
        return
        
    attr_name = "user.XrdCks.adler32"
    print(f"Querying extended attribute '{attr_name}' on: {local_path}")
    
    try:
        # Check if listxattr has it
        try:
            attrs = os.listxattr(local_path)
            print(f"Available extended attributes: {attrs}")
        except Exception as e:
            print(f"listxattr failed: {e}")
            
        attr_val = os.getxattr(local_path, attr_name)
        print(f"Raw attribute value (hex): {attr_val.hex()}")
        print(f"Raw attribute value length: {len(attr_val)} bytes")
        
        if len(attr_val) >= 36:
            # Extract bytes 32-35
            chksum_bytes = attr_val[32:36]
            checksum = chksum_bytes.hex()
            print(f"Successfully parsed Adler32 checksum: {checksum}")
        else:
            print(f"Attribute value too short ({len(attr_val)} bytes), expected >= 36")
    except Exception as e:
        print(f"getxattr failed: {e}")
        print("Traceback:")
        traceback.print_exc()

def test_webdav_digest(uri):
    print("\n=== Testing WebDAV Digest Query ===")
    try:
        from lsst.resources import ResourcePath
        from lsst.resources.davutils import DavClientPool
        
        print("Imported lsst.resources and DavClientPool successfully.")
        
        # Initialize client pool if not already initialized
        pool = DavClientPool._instance
        if pool is None:
            print("DavClientPool._instance is None. Instantiating via mock config/pool...")
            from lsst.resources.davutils import DavConfigPool
            # Attempt to use active instance or trigger resource path initialization
            rp = ResourcePath(uri)
            # Fetching info usually triggers DavClientPool initialization
            try:
                rp.get_info()
            except Exception:
                pass
            pool = DavClientPool._instance
            
        if pool is None:
            print("ERROR: Could not initialize DavClientPool.")
            return
            
        print("Client Pool clients:", list(pool._clients.keys()))
        client = pool.get_client_for_url(uri)
        print(f"Client class selected: {client.__class__.__name__}")
        print(f"Client base URL: {client._base_url}")
        
        # Test Server header
        try:
            details = client.get_server_details(client._base_url)
            print("Server details:", details)
        except Exception as e:
            print("Failed to get server details:", e)
            
        print(f"Sending HEAD request with Want-Digest: adler32 to: {uri}")
        resp = client.head(uri, headers={"Want-Digest": "adler32"})
        print(f"HTTP Response Status: {resp.status} {resp.reason}")
        print("HTTP Response Headers:")
        for header, val in resp.headers.items():
            print(f"  {header}: {val}")
            
        digest = resp.headers.get("Digest")
        if digest:
            print(f"Found Digest Header: {digest}")
            parts = digest.split("=")
            if len(parts) == 2 and parts[0].lower() == "adler32":
                print(f"Parsed Adler32 from Digest: {parts[1].strip().lower()}")
            else:
                print("Digest format does not match expected 'adler32=value'")
        else:
            print("No 'Digest' header returned by WebDAV server.")
            
    except Exception as e:
        print(f"WebDAV Digest check failed: {e}")
        print("Traceback:")
        traceback.print_exc()

def test_standard_getinfo(uri):
    print("\n=== Testing Standard lsst.resources get_info ===")
    try:
        from lsst.resources import ResourcePath
        rp = ResourcePath(uri)
        info = rp.get_info()
        print(f"Size: {info.size}")
        print(f"Checksums: {getattr(info, 'checksums', None)}")
    except Exception as e:
        print(f"get_info failed: {e}")
        print("Traceback:")
        traceback.print_exc()

def test_manual_download(uri):
    print("\n=== Testing Manual Download & Adler32 Calculation ===")
    import time
    try:
        from lsst.resources import ResourcePath
        rp = ResourcePath(uri)
        
        start = time.time()
        adler32 = zlib.adler32(b"")
        buffer_size = 10 * 1024 * 1024
        total_bytes = 0
        
        with rp.open("rb") as f:
            while buffer := f.read(buffer_size):
                adler32 = zlib.adler32(buffer, adler32)
                total_bytes += len(buffer)
                
        elapsed = time.time() - start
        checksum = f"{adler32 & 0xffffffff:08x}"
        print(f"Calculated Adler32: {checksum}")
        print(f"Read {total_bytes} bytes in {elapsed:.4f} seconds ({total_bytes / elapsed / 1024 / 1024:.2f} MB/s)")
    except Exception as e:
        print(f"Manual download failed: {e}")
        print("Traceback:")
        traceback.print_exc()

if __name__ == "__main__":
    default_uri = (
        "davs://xgate.hec.lancs.ac.uk:1094/cephfs/grid/lsst/repos/dp2_prep/"
        "u/dmckayuk/w_2026_23/DM-55252/20260619T131002Z/analyzeSingleVisitStarAssociation_config/"
        "analyzeSingleVisitStarAssociation_config_u_dmckayuk_w_2026_23_DM-55252_20260619T131002Z.py"
    )
    
    uri = sys.argv[1] if len(sys.argv) > 1 else default_uri
    
    print(f"Running Checksum Diagnostics on URI:\n{uri}\n")
    
    local_path = test_local_path(uri)
    test_cephfs_xattr(local_path)
    test_webdav_digest(uri)
    test_standard_getinfo(uri)
    test_manual_download(uri)

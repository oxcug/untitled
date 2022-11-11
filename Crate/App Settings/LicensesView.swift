//
//  LicensesView.swift
//  untitled
//
//  Created by Mike Choi on 11/11/22.
//

import SwiftUI

struct RepoView: View {
    let repo: Repo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(repo.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.blue)
            
            Text(repo.copyright)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text(repo.copyrightDetails)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
            
            Text("\n")
        }
    }
}

struct LicensesView: View {
    var body: some View {
        List {
            ForEach(Repo.all) { repo in
                RepoView(repo: repo)
                    .listRowSeparator(.hidden)
            }
            
            Text(verbatim:
"""
                             I8            I8    ,dPYb,                  8I
                             I8            I8    IP'`Yb                  8I
                          88888888  gg  88888888 I8  8I                  8I
                             I8     ""     I8    I8  8'                  8I
 gg      gg   ,ggg,,ggg,     I8     gg     I8    I8 dP   ,ggg,     ,gggg,8I
 I8      8I  ,8" "8P" "8,    I8     88     I8    I8dP   i8" "8i   dP"  "Y8I
 I8,    ,8I  I8   8I   8I   ,I8,    88    ,I8,   I8P    I8, ,8I  i8'    ,8I
,d8b,  ,d8b,,dP   8I   Yb, ,d88b, _,88,_ ,d88b, ,d8b,_  `YbadP' ,d8,   ,d8b, d8b
8P'"Y88P"`Y88P'   8I   `Y888P""Y888P""Y888P""Y888P'"Y88888P"Y888P"Y8888P"`Y8 Y8P
                                                                                 
""")
            .font(.system(size: 6, weight: .regular, design: .monospaced))
            .listRowSeparator(.hidden)
            
            Text(verbatim:
"""
Thanks for swinging by ❤️

Cheers,
Mike JS. Choi
@guard_if

Made in London, UK
""")
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}


struct LicensesView_Previews: PreviewProvider {
    static var previews: some View {
        LicensesView()
    }
}
